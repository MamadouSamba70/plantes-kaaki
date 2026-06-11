import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/file_saver.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';
import '../../models/scan.dart';

class ResearcherDashboard extends StatefulWidget {
  const ResearcherDashboard({super.key});

  @override
  State<ResearcherDashboard> createState() => _ResearcherDashboardState();
}

class _ResearcherDashboardState extends State<ResearcherDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ScanProvider>(context, listen: false).fetchGlobalHistory();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  // Generate CSV from history list
  String _generateCSV(List<ScanModel> scans) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('id,user_id,disease,confidence,severity,created_at');
    for (var scan in scans) {
      buffer.writeln(
        '${scan.id},${scan.userId},"${scan.disease}",${scan.confidence},${scan.severity},${scan.createdAt.toIso8601String()}'
      );
    }
    return buffer.toString();
  }

  // Generate JSON from history list (proper JSON format)
  String _generateJSON(List<ScanModel> scans) {
    final List<Map<String, dynamic>> list = scans.map((s) => s.toMap()).toList();
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(list);
  }

  Future<void> _exportData(String type, String content, List<ScanModel> scans) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = type.toLowerCase();
      final fileName = 'kaakiscan_diagnostics_$timestamp.$extension';
      final mimeType = type == 'CSV' ? 'text/csv' : 'application/json';

      await saveAndShareFile(
        fileName,
        content,
        mimeType,
        subject: 'KaakiScan — Export épidémiologique ($type) — ${scans.length} diagnostics',
        text: 'Export généré par KaakiScan le ${DateTime.now().toLocal().toString().substring(0, 16)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export : $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final scanProvider = Provider.of<ScanProvider>(context);
    final user = auth.user;

    final scans = scanProvider.history;
    final total = scans.length;
    final healthy = scans.where((s) => s.disease.toLowerCase().contains('sain')).length;
    final sick = total - healthy;

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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${user?.fullName.split(' ').first ?? 'Chercheur'}',
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
                            'Portail d\'analyse scientifique',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.go('/profile'),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          child: Text(
                            user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'R',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Model Specs Zone
                  const Text(
                    'Spécifications du Modèle MobileNetV2',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildModelSpecs(),
                  const SizedBox(height: 24),

                  // Data Export Section
                  const Text(
                    'Exportation de données épidémiologiques',
                    style: TextStyle(
                      fontFamily: 'Outfit',
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
                      border: Border.all(color: const Color(0xFFE8EBE8)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Exportez l\'ensemble des diagnostics enregistrés dans la base pour vos outils d\'analyses statistiques (R, Python, Excel).',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.table_chart_rounded, size: 18),
                                label: const Text('Export CSV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                onPressed: total == 0 ? null : () {
                                  final csv = _generateCSV(scans);
                                  _exportData('CSV', csv, scans);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F3E12).withOpacity(0.08),
                                  foregroundColor: const Color(0xFF0F3E12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                  side: BorderSide(color: const Color(0xFF0F3E12).withOpacity(0.2)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.code_rounded, size: 18),
                                label: const Text('Export JSON', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                onPressed: total == 0 ? null : () {
                                  final jsonStr = _generateJSON(scans);
                                  _exportData('JSON', jsonStr, scans);
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Diagnostics list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Registre global des diagnostics',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$total scans',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (scanProvider.isLoadingHistory)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (scans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Column(
                        children: [
                          Icon(Icons.folder_open_rounded, size: 40, color: AppColors.textSecondary.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          const Text(
                            'Aucune donnée dans la base de diagnostic.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          )
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: scans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = scans[index];
                        final isHealthy = item.disease.toLowerCase().contains('sain');
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8EBE8)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: AppColors.primary.withOpacity(0.05),
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 20),
                                        )
                                      : const Icon(Icons.science_outlined, color: AppColors.primary, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.disease,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Certitude : ${(item.confidence * 100).toStringAsFixed(1)}% • Id: ${item.id}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isHealthy ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: isHealthy ? AppColors.success : AppColors.danger,
                                size: 16,
                              )
                            ],
                          ),
                        );
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
          BottomNavigationBarItem(icon: Icon(Icons.biotech_rounded, size: 22), label: 'Recherche'),
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

  Widget _buildModelSpecs() {
    final specs = [
      {'label': 'Architecture', 'val': 'MobileNetV2', 'icon': Icons.layers_outlined},
      {'label': 'Précision globale', 'val': '92.4%', 'icon': Icons.offline_pin_outlined},
      {'label': 'Résolution entrée', 'val': '224x224x3 px', 'icon': Icons.aspect_ratio_rounded},
      {'label': 'Vitesse inférence', 'val': '~120ms', 'icon': Icons.speed_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
      ),
      itemCount: specs.length,
      itemBuilder: (context, index) {
        final spec = specs[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EBE8)),
          ),
          child: Row(
            children: [
              Icon(spec['icon'] as IconData, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spec['label'] as String,
                      style: TextStyle(fontSize: 9, color: AppColors.textSecondary.withOpacity(0.8), fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec['val'] as String,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
