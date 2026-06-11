import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/colors.dart';
import '../../models/scan.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';

class AgronomistDashboard extends StatefulWidget {
  const AgronomistDashboard({super.key});

  @override
  State<AgronomistDashboard> createState() => _AgronomistDashboardState();
}

class _AgronomistDashboardState extends State<AgronomistDashboard> {
  @override
  void initState() {
    super.initState();
    // Load community scans on startup instead of expert's own scans
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScanProvider>(context, listen: false).fetchGlobalHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final auth = Provider.of<AuthProvider>(context);
    final scanProvider = Provider.of<ScanProvider>(context);
    final user = auth.user;
    final history = scanProvider.history;

    // Calculate community epidemiological statistics
    final totalCommunityScans = history.length;
    final healthyCommunityScans = history.where((s) => s.disease.toLowerCase() == 'feuille saine').length;
    final activeInfections = totalCommunityScans - healthyCommunityScans;
    
    // Infestation Rate
    final infestationRate = totalCommunityScans > 0 
        ? ((activeInfections / totalCommunityScans) * 100).toStringAsFixed(0) 
        : '0';

    // Role dynamic definitions
    final isResearcher = user?.role?.toLowerCase() == 'researcher';
    final expertTitle = isResearcher ? 'Chercheur Botanique' : 'Expert Agronome';
    final expertSubtitle = isResearcher 
        ? 'Suivi de la biodiversité & innovations phytosanitaires' 
        : 'Consultation & recommandation sur les maladies du bananier';
    final primaryThemeColor = isResearcher ? const Color(0xFF7B1FA2) : const Color(0xFF0288D1);
    final gradientColors = isResearcher
        ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
        : [const Color(0xFF0D47A1), const Color(0xFF0288D1)];

    // Regional disease counts
    final Map<String, int> regionalInfections = {};
    for (final s in history) {
      if (s.disease.toLowerCase() != 'feuille saine') {
        regionalInfections[s.disease] = (regionalInfections[s.disease] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => scanProvider.fetchGlobalHistory(),
          color: primaryThemeColor,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dynamic Scientific Header (No clichés, high-end tech styling) ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryThemeColor.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expertTitle.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user?.fullName ?? 'Expert KaakiScan',
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Premium Quick Navigation Actions
                          Material(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.push('/profile'),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        expertSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Real-time Epidemiological Health Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isResearcher ? Icons.biotech_rounded : Icons.radar_rounded,
                                color: const Color(0xFFFFD54F),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pression Épidémique Régionale',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    infestationRate == '0' 
                                        ? 'Aucune menace détectée' 
                                        : '$infestationRate% de cas d\'infection actifs',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$totalCommunityScans scans',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Epidemiological Statistics grid ──
                      const Text(
                        'Indicateurs épidémiologiques globaux',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.nature_people_outlined,
                              value: '$healthyCommunityScans',
                              label: 'Feuilles saines',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.coronavirus_outlined,
                              value: '$activeInfections',
                              label: 'Infections actives',
                              color: activeInfections > 0 ? AppColors.danger : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Regional Disease Breakdown Chart ──
                      if (regionalInfections.isNotEmpty) ...[
                        const Text(
                          'Souches identifiées dans la région',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: regionalInfections.entries.map((entry) {
                              return _buildDiseaseProgressLine(
                                disease: entry.key,
                                count: entry.value,
                                totalInfections: activeInfections,
                                themeColor: primaryThemeColor,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Urgence de terrain alerts (Live farmer scans) ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Alertes phytosanitaires récentes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: primaryThemeColor),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('Historique global', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => context.push('/history'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (scanProvider.isLoadingHistory)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: CircularProgressIndicator(color: primaryThemeColor),
                          ),
                        )
                      else if (history.isEmpty)
                        _buildEmptyCommunityState()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: history.length > 5 ? 5 : history.length,
                          itemBuilder: (ctx, i) {
                            final scan = history[i];
                            return _buildEpidAlertTile(scan, primaryThemeColor);
                          },
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryThemeColor,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Épidémiologie'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Scanner'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 1) context.push('/scan');
          if (index == 2) context.push('/history');
          if (index == 3) context.push('/profile');
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseProgressLine({
    required String disease,
    required int count,
    required int totalInfections,
    required Color themeColor,
  }) {
    final double percentage = totalInfections > 0 ? count / totalInfections : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  disease,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count signalements',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: Colors.grey.shade100,
              color: disease.toLowerCase().contains('sigatoka') 
                  ? AppColors.danger 
                  : (disease.toLowerCase().contains('panama') ? AppColors.warning : themeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpidAlertTile(ScanModel scan, Color primaryColor) {
    final isHealthy = scan.disease.toLowerCase() == 'feuille saine';
    final dateFormatted = DateFormat('dd/MM/yyyy à HH:mm').format(scan.createdAt);
    
    Color alertColor = AppColors.success;
    if (!isHealthy) {
      alertColor = scan.severity.toString().split('.').last == 'high' 
          ? AppColors.danger 
          : AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // View detailed diagnostic result
            final scanProvider = Provider.of<ScanProvider>(context, listen: false);
            scanProvider.clearImage();
            scanProvider.setMockResult(scan);
            context.push('/result');
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Alert colored indicator badge
                Container(
                  width: 6,
                  height: 48,
                  decoration: BoxDecoration(
                    color: alertColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),

                // Info columns
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              scan.disease,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: alertColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(scan.confidence * 100).toStringAsFixed(0)}% cert.',
                              style: TextStyle(
                                color: alertColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_pin_circle_outlined, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            scan.userId.startsWith('farmer') 
                                ? 'Agriculteur ${scan.userId.replaceAll('farmer_', '').toUpperCase()}' 
                                : 'Producteur local',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            dateFormatted,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCommunityState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.health_and_safety_outlined, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune alerte phytosanitaire',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tous les signalements reçus indiquent des plantations saines.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
