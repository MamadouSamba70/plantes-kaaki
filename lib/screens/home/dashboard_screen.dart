import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Fetch scan history on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        if (authProvider.user!.isSuperAdmin) {
          context.go('/admin');
          return;
        }
        if (authProvider.user!.isAgronomist) {
          context.go('/agronomy');
          return;
        }
        if (authProvider.user!.isResearcher) {
          context.go('/research');
          return;
        }
        Provider.of<ScanProvider>(context, listen: false)
            .fetchHistory(authProvider.user!.uid);
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    
    final authProvider = Provider.of<AuthProvider>(context);
    final scanProvider = Provider.of<ScanProvider>(context);
    final user = authProvider.user;

    // Calculate stats
    final totalScans = scanProvider.history.length;
    final healthyScans = scanProvider.history.where((s) => s.disease.toLowerCase() == 'feuille saine').length;
    final sickScans = totalScans - healthyScans;

    return Scaffold(
      backgroundColor: AppColors.background, // Premium green backdrop
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? size.width * 0.1 : 20.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Header Row (Refined typography)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bonjour,',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.fullName ?? 'Agriculteur',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 22),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Aucune nouvelle alerte phytosanitaire.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Banner card (Premium organic forest green)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3E12),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F3E12).withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Protégez vos bananiers',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Analysez une feuille de bananier pour identifier instantanément les menaces.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F3E12),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.camera_alt_outlined, size: 16),
                              label: const Text(
                                'Scanner maintenant',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => context.go('/scan'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.spa_rounded,
                        size: 72,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Quick Stats Section Title
                const Text(
                  'Vue d\'ensemble 📈',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Cards row
                Row(
                  children: [
                    _buildStatCard('Scans', totalScans.toString(), Icons.analytics_outlined, const Color(0xFF0F3E12)),
                    const SizedBox(width: 10),
                    _buildStatCard('Feuilles saines', healthyScans.toString(), Icons.check_circle_outline_rounded, AppColors.success),
                    const SizedBox(width: 10),
                    _buildStatCard('Feuilles malades', sickScans.toString(), Icons.warning_amber_rounded, AppColors.danger),
                  ],
                ),
                const SizedBox(height: 28),

                // Recent Diagnostics List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Derniers Diagnostics 🍌',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text(
                        'Voir tout',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Diagnostics List
                if (scanProvider.isLoadingHistory)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                else if (scanProvider.history.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8EBE8)),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_outlined, size: 40, color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucun diagnostic enregistré',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Prenez un scan pour démarrer votre suivi.',
                            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: scanProvider.history.take(3).length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final scan = scanProvider.history[index];
                      return _buildRecentScanCard(scan);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
          if (index == 1) context.go('/scan');
          if (index == 2) context.go('/history');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EBE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScanCard(dynamic scan) {
    Color severityColor = AppColors.success;
    if (scan.disease.toLowerCase() != 'feuille saine') {
      if (scan.severity.toString().split('.').last == 'high') {
        severityColor = AppColors.danger;
      } else {
        severityColor = AppColors.warning;
      }
    }

    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(scan.createdAt);

    return InkWell(
      onTap: () {
        final scanProvider = Provider.of<ScanProvider>(context, listen: false);
        scanProvider.clearImage();
        scanProvider.setMockResult(scan);
        context.push('/result');
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EBE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Preview (with fallback)
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

            // Scan info
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
                      Expanded(
                        child: Text(
                          'Gravité: ${scan.severity.toString().split('.').last == 'high' ? 'Élevée' : (scan.severity.toString().split('.').last == 'medium' ? 'Moyenne' : 'Faible')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
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

            // Confidence & Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
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
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 18),
              ],
            ),
          ],
        ),
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
