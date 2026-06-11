import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

/// Service de découverte automatique du serveur KaakiScan sur le réseau local.
/// Il scanne le subnet Wi-Fi en parallèle et retourne la première IP qui répond.
class ServerDiscovery {
  static const int _port = 8000;
  static const String _pingPath = '/api/ping';
  static const String _cachedIpKey = 'kaakiscan_server_ip';
  static const Duration _probeTimeout = Duration(milliseconds: 800);

  /// IPs prioritaires à essayer avant le scan complet.
  /// Mettez ici l'IP de votre PC de développement. Elle est essayée en premier
  /// pour un démarrage ultra-rapide même si le scan réseau est bloqué.
  static const List<String> _priorityIps = [
    '10.13.226.15', // PC de développement (Wi-Fi)
    '192.168.1.1',  // Passerelle commune
    '10.0.0.1',
  ];

  /// Lance la découverte. Retourne l'URL de base (ex: "http://192.168.1.5:8000")
  /// ou null si aucun serveur n'est trouvé.
  static Future<String?> discover({void Function(String)? onStatus}) async {
    if (kIsWeb) return null;

    // ── Étape 1 : Essayer l'IP mise en cache (la plus rapide) ──────────────
    final cachedIp = await _getCachedIp();
    if (cachedIp != null) {
      onStatus?.call('Vérification du serveur connu ($cachedIp)...');
      if (await _probeIp(cachedIp)) {
        onStatus?.call('Serveur confirmé (cache) : $cachedIp');
        return 'http://$cachedIp:$_port';
      }
    }

    // ── Étape 2 : Essayer les IPs prioritaires connues ─────────────────────
    onStatus?.call('Essai des IPs prioritaires...');
    for (final ip in _priorityIps) {
      if (ip == cachedIp) continue; // déjà essayé
      if (await _probeIp(ip)) {
        onStatus?.call('Serveur trouvé (priorité) : $ip');
        await _saveCachedIp(ip);
        return 'http://$ip:$_port';
      }
    }

    // ── Étape 3 : Détecter le subnet Wi-Fi de l'appareil ───────────────────
    onStatus?.call('Recherche sur le réseau local...');
    final subnet = await _detectSubnet();
    if (subnet == null) {
      onStatus?.call('Impossible de détecter le réseau Wi-Fi.');
      // Retourner l'IP prioritaire principale comme fallback absolu
      return 'http://${_priorityIps.first}:$_port';
    }

    // ── Étape 4 : Scanner tout le subnet en parallèle ──────────────────────
    onStatus?.call('Scan du réseau $subnet.0/24...');
    final completer = Completer<String?>();
    int remaining = 254;

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      _probeIp(ip).then((reachable) {
        remaining--;
        if (reachable && !completer.isCompleted) {
          _saveCachedIp(ip);
          completer.complete(ip);
        } else if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    // Timeout global de 8 secondes pour le scan
    final foundIp = await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );

    if (foundIp != null) {
      onStatus?.call('Serveur trouvé (scan) : $foundIp');
      return 'http://$foundIp:$_port';
    }

    // ── Étape 5 : Fallback absolu sur l'IP prioritaire principale ──────────
    onStatus?.call('Scan échoué. Utilisation de l\'IP de secours : ${_priorityIps.first}');
    return 'http://${_priorityIps.first}:$_port';
  }

  /// Tente de joindre /api/ping sur une IP donnée.
  static Future<bool> _probeIp(String ip) async {
    try {
      final url = Uri.parse('http://$ip:$_port$_pingPath');
      final response = await http.get(url).timeout(_probeTimeout);
      return response.statusCode == 200 &&
          response.body.contains('KaakiScan');
    } catch (_) {
      return false;
    }
  }

  /// Détecte le préfixe du subnet local (ex: "192.168.1").
  static Future<String?> _detectSubnet() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          // Exclure les adresses APIPA (169.254.x.x) et loopback
          if (ip.startsWith('192.168.') ||
              ip.startsWith('10.') ||
              (ip.startsWith('172.') && !ip.startsWith('172.31.'))) {
            final parts = ip.split('.');
            return '${parts[0]}.${parts[1]}.${parts[2]}';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Récupère l'IP mise en cache depuis SharedPreferences.
  static Future<String?> _getCachedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_cachedIpKey);
    } catch (_) {
      return null;
    }
  }

  /// Sauvegarde l'IP trouvée pour accélérer le prochain démarrage.
  static Future<void> _saveCachedIp(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedIpKey, ip);
    } catch (_) {}
  }

  /// Efface le cache (utile si le réseau change).
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedIpKey);
    } catch (_) {}
  }
}
