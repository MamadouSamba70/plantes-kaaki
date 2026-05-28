import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/scan.dart';
import 'api_service.dart';

class ScanService {
  // ─── Perform Scan Diagnostic ──────────────────────────────────────────────
  Future<ScanModel> performDiagnostic(File imageFile, String userId) async {
    final response = await ApiService.uploadImage('/api/scan', imageFile);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      
      // Assure absolute URL for images coming from backend
      if (data['image_url'] != null && data['image_url'].startsWith('/')) {
        data['image_url'] = '${ApiService.baseUrl}${data['image_url']}';
      }
      
      return ScanModel.fromMap(data);
    } else {
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (_) {}
      throw Exception(errorData['detail'] ?? 'Erreur lors de l\'analyse de l\'image (Code: ${response.statusCode})');
    }
  }

  // ─── Get User's Scans ───────────────────────────────────────────────────
  Future<List<ScanModel>> getUserScans(String userId) async {
    final response = await ApiService.get('/api/scans');
    
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) {
        if (item['image_url'] != null && item['image_url'].startsWith('/')) {
          item['image_url'] = '${ApiService.baseUrl}${item['image_url']}';
        }
        return ScanModel.fromMap(item);
      }).toList();
    } else {
      throw Exception('Erreur lors de la récupération de l\'historique.');
    }
  }

  // ─── Get All Scans (Admin/Expert) ───────────────────────────────────────
  Future<List<ScanModel>> getAllScans() async {
    final response = await ApiService.get('/api/scans/all');
    
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) {
        if (item['image_url'] != null && item['image_url'].startsWith('/')) {
          item['image_url'] = '${ApiService.baseUrl}${item['image_url']}';
        }
        return ScanModel.fromMap(item);
      }).toList();
    } else {
      throw Exception('Erreur lors de la récupération de tous les diagnostics.');
    }
  }

  // ─── Delete Scan ────────────────────────────────────────────────────────
  Future<void> deleteScan(String scanId) async {
    final response = await ApiService.delete('/api/scans/$scanId');
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression du scan.');
    }
  }
}
