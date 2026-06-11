import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../models/scan.dart';

class AgronomistDashboard extends StatefulWidget {
  const AgronomistDashboard({super.key});

  @override
  State<AgronomistDashboard> createState() => _AgronomistDashboardState();
}

class _AgronomistDashboardState extends State<AgronomistDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;
  String _selectedFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    // Fetch global scans list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScanProvider>(context, listen: false).fetchGlobalHistory();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final scanProvider = Provider.of<ScanProvider>(context);
    final user = auth.user;

    final scans = scanProvider.history;
    final filteredScans = _filterScans(scans);

    final total = scans.length;
    final healthy = scans.where((s) => s.disease.toLowerCase().contains('sain')).length;
    final sick = total - healthy;
    final alertScans = scans.where((s) => s.isHighSeverity).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await scanProvider.fetchGlobalHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Header Block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour, Dr. ${user?.fullName.split(' ').first ?? 'Agronome'}',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Expertise et suivi phytosanitaire',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Panel
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Analyses',
                          '$total',
                          Icons.analytics_rounded,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Cas Malades',
                          '$sick',
                          Icons.warning_amber_rounded,
                          AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Cas Sains',
                          '$healthy',
                          Icons.check_circle_outline_rounded,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Alerts Section (Diseases with High severity)
                  if (alertScans.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.notification_important_rounded, color: AppColors.danger, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Alertes prioritaires (${alertScans.length})',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: alertScans.length,
                        itemBuilder: (context, index) {
                          final item = alertScans[index];
                          return _buildAlertCard(item);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Filter Section
                  const Text(
                    'Diagnostics parcellaires',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilters(),

                  const SizedBox(height: 16),

                  // Scans List
                  if (scanProvider.isLoadingHistory)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (filteredScans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60.0),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'Aucun diagnostic ne correspond à ce filtre.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredScans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredScans[index];
                        return _buildScanTile(item, scanProvider);
                      },
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary.withOpacity(0.6),
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 22), label: 'Tableau'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined, size: 22), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined, size: 22), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 22), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) context.go('/scan');
          if (index == 2) context.go('/history');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  List<ScanModel> _filterScans(List<ScanModel> allScans) {
    if (_selectedFilter == 'Tous') return allScans;
    if (_selectedFilter == 'Malades') return allScans.where((s) => !s.disease.toLowerCase().contains('sain')).toList();
    if (_selectedFilter == 'Sains') return allScans.where((s) => s.disease.toLowerCase().contains('sain')).toList();
    return allScans.where((s) => s.disease.toLowerCase().contains(_selectedFilter.toLowerCase())).toList();
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EBE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
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
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(ScanModel item) {
    return GestureDetector(
      onTap: () {
        Provider.of<ScanProvider>(context, listen: false).setMockResult(item);
        context.go('/result');
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_rounded, color: AppColors.danger, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.disease,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Confiance: ${(item.confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'INTERVENIR',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Tous', 'Malades', 'Sains', 'Sigatoka', 'Moko', 'Panama'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              elevation: 0,
              pressElevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : const Color(0xFFE8EBE8),
                ),
              ),
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedFilter = filter);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildScanTile(ScanModel item, ScanProvider provider) {
    final isHealthy = item.disease.toLowerCase().contains('sain');
    return InkWell(
      onTap: () {
        provider.setMockResult(item);
        context.go('/result');
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EBE8)),
        ),
        child: Row(
          children: [
            // Image Preview or Icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.primary.withOpacity(0.05),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, color: AppColors.textSecondary),
                      )
                    : const Icon(Icons.image_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 14),
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.disease,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confiance : ${(item.confidence * 100).toStringAsFixed(0)}% • Gravité : ${item.severityLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Badge / Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isHealthy ? AppColors.success.withOpacity(0.08) : AppColors.danger.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isHealthy ? Icons.verified_rounded : Icons.warning_amber_rounded,
                color: isHealthy ? AppColors.success : AppColors.danger,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
