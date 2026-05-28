import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = 'all'; // 'all', 'healthy', 'alerts'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.isSuperAdmin == true) {
        context.go('/admin');
        return;
      }
      _refreshHistory();
    });
  }

  Future<void> _refreshHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      await Provider.of<ScanProvider>(context, listen: false)
          .fetchHistory(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);

    // Apply filters
    final filteredHistory = scanProvider.history.where((scan) {
      if (_activeFilter == 'healthy') {
        return scan.disease.toLowerCase() == 'feuille saine';
      } else if (_activeFilter == 'alerts') {
        return scan.disease.toLowerCase() != 'feuille saine';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background, // Green backdrop
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => context.go('/home'),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: const Text(
          'Historique des Scans',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _refreshHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                _buildFilterChip('Tous', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Sains', 'healthy'),
                const SizedBox(width: 8),
                _buildFilterChip('Maladies', 'alerts'),
              ],
            ),
          ),

          // Main list or placeholder
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHistory,
              color: const Color(0xFF0F3E12),
              backgroundColor: Colors.white,
              child: scanProvider.isLoadingHistory
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F3E12), strokeWidth: 2))
                  : (filteredHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          itemCount: filteredHistory.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final scan = filteredHistory[index];
                            return _buildScanTile(scan);
                          },
                        )),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F3E12),
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.6),
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined, size: 22), activeIcon: Icon(Icons.dashboard_rounded, size: 22), label: 'Tableau'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined, size: 22), activeIcon: Icon(Icons.camera_alt_rounded, size: 22), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined, size: 22), activeIcon: Icon(Icons.history_rounded, size: 22), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 22), activeIcon: Icon(Icons.person_rounded, size: 22), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/scan');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _activeFilter == filterValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeFilter = filterValue;
          });
        }
      },
      selectedColor: Colors.white,
      backgroundColor: AppColors.primary.withOpacity(0.08),
      disabledColor: Colors.transparent,
      elevation: 0,
      pressElevation: 0,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? const Color(0xFF0F3E12) : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? Colors.transparent : AppColors.primary.withOpacity(0.12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'Aucun scan trouvé.';
    if (_activeFilter == 'healthy') message = 'Aucun scan de feuille saine.';
    if (_activeFilter == 'alerts') message = 'Aucune maladie détectée.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: AppColors.textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tirez vers le bas pour rafraîchir',
                style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteScan(String scanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Supprimer le scan ?', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment supprimer ce diagnostic de votre historique ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);
      if (authProvider.user != null) {
        final success = await scanProvider.deleteScan(scanId, authProvider.user!.uid);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🗑️ Diagnostic supprimé avec succès.'),
              backgroundColor: AppColors.textPrimary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Widget _buildScanTile(dynamic scan) {
    Color severityColor = const Color(0xFF0F3E12);
    if (scan.disease.toLowerCase() != 'feuille saine') {
      final severityName = scan.severity.toString().split('.').last;
      if (severityName == 'high') {
        severityColor = const Color(0xFFC62828);
      } else {
        severityColor = const Color(0xFFE5A93C);
      }
    }

    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(scan.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EBE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                final scanProvider = Provider.of<ScanProvider>(context, listen: false);
                scanProvider.clearImage();
                scanProvider.setMockResult(scan);
                context.push('/result');
              },
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: scan.imageUrl.startsWith('http')
                            ? Image.network(scan.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildFallbackImage())
                            : (File(scan.imageUrl).existsSync()
                                ? Image.file(File(scan.imageUrl), fit: BoxFit.cover)
                                : _buildFallbackImage()),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scan.disease,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: severityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Gravité: ${scan.severity.toString().split('.').last == 'high' ? 'Élevée' : (scan.severity.toString().split('.').last == 'medium' ? 'Moyenne' : 'Faible')}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateFormatted,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3E12).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0F3E12).withOpacity(0.1), width: 1),
                  ),
                  child: Text(
                    '${(scan.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF0F3E12),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _confirmDeleteScan(scan.id),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        final scanProvider = Provider.of<ScanProvider>(context, listen: false);
                        scanProvider.clearImage();
                        scanProvider.setMockResult(scan);
                        context.push('/result');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      color: const Color(0xFF0F3E12).withOpacity(0.06),
      child: const Icon(Icons.image_outlined, color: Color(0xFF0F3E12), size: 22),
    );
  }
}
