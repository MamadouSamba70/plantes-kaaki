import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.user != null) {
        Provider.of<ScanProvider>(context, listen: false).fetchHistory(auth.user!.uid);
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

    final totalScans = scanProvider.history.length;
    final healthyScans = scanProvider.history.where((s) => s.disease.toLowerCase() == 'feuille saine').length;
    final sickScans = totalScans - healthyScans;
    final healthRate = totalScans > 0 ? ((healthyScans / totalScans) * 100).toStringAsFixed(0) : '100';

    Color roleColor = const Color(0xFF0F3E12);
    Color roleBg = const Color(0xFFE8F5E9);
    String roleLabel = 'Producteur Agricole';
    String roleEmoji = '🍌';
    String roleQuote = 'Cultive le bananier avec amour, protège sa plantation avec intelligence.';
    List<Widget> roleStats = [];

    switch (user?.role?.toLowerCase()) {
      case 'superadmin':
        roleColor = const Color(0xFFD84315);
        roleBg = const Color(0xFFFBE9E7);
        roleLabel = 'Administrateur';
        roleEmoji = '🛡️';
        roleQuote = 'Protecteur de KaakiScan, garant de la sécurité de la communauté.';
        roleStats = [
          _buildStatCard('Utilisateurs', 'Actifs', Icons.people_alt_rounded, roleColor),
          _buildStatCard('Validation', 'En cours', Icons.security_rounded, roleColor),
          _buildStatCard('Mode', 'Démo', Icons.storage_rounded, roleColor),
        ];
        break;
      case 'farmer':
      default:
        roleStats = [
          _buildStatCard('Scans', '$totalScans', Icons.camera_alt_outlined, roleColor),
          _buildStatCard('Santé', '$healthRate%', Icons.favorite_border_rounded, healthyScans > 0 ? AppColors.success : roleColor),
          _buildStatCard('Alertes', '$sickScans', Icons.warning_amber_rounded, sickScans > 0 ? AppColors.danger : roleColor),
        ];
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Zone ────────────────────────────────────────────────
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Container(
                          padding: const EdgeInsets.all(10),
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
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Mon Profil',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Avatar Card (overlapping header) ──────────────────────────
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8EBE8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar + emoji badge
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: roleBg,
                                  border: Border.all(color: roleColor.withOpacity(0.2), width: 2),
                                ),
                                child: Center(
                                  child: Text(
                                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: roleColor,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE8EBE8)),
                                ),
                                child: Text(roleEmoji, style: const TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user?.fullName ?? 'Agriculteur',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F3E12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: roleColor.withOpacity(0.15)),
                            ),
                            child: Text(
                              roleLabel.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            roleQuote,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary.withOpacity(0.8),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Body content ──────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 60 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Admin shortcut
                      if (user?.role == 'superadmin') ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD84315),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                          label: const Text('Panneau d\'Administration 🛡️', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => context.go('/admin'),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Stats Section
                      const Text(
                        'Tableau de bord 📈',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: roleStats
                            .map((item) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                    child: item,
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Technical Info section
                      const Text(
                        'Informations du compte ⚙️',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
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
                          children: [
                            _buildProfileTile(
                              icon: Icons.email_outlined,
                              title: 'Adresse e-mail',
                              value: user?.email ?? 'Non renseigné',
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildProfileTile(
                              icon: Icons.cloud_done_outlined,
                              title: 'Mode de connexion',
                              value: authProvider.isMockMode
                                  ? 'Mode Démo (Local)'
                                  : 'Connecté au cloud Firebase',
                              valueColor: authProvider.isMockMode ? AppColors.warning : AppColors.success,
                            ),
                            const Divider(height: 1, indent: 56, endIndent: 16),
                            _buildProfileTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'Statut du Compte',
                              value: user?.isApproved == true ? 'Validé par l\'Admin ✅' : 'En attente de validation ⏳',
                              valueColor: user?.isApproved == true ? AppColors.success : AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Help cards
                      _buildHelpCard(
                        'Comment bien scanner une feuille ? 🍌',
                        'Prenez la photo sous une lumière naturelle et évitez les reflets sur la feuille.',
                        Icons.tips_and_updates_rounded,
                        const Color(0xFFE5A93C),
                      ),
                      const SizedBox(height: 12),
                      _buildHelpCard(
                        'Besoin d\'un conseil agricole ? 📞',
                        'Contactez nos conseillers agricoles pour obtenir des recommandations personnalisées.',
                        Icons.support_agent_rounded,
                        const Color(0xFF0288D1),
                      ),
                      const SizedBox(height: 28),

                      // Logout button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger.withOpacity(0.06),
                          foregroundColor: AppColors.danger,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.danger, width: 1),
                          ),
                        ),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Déconnexion', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                              content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Déconnexion', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            await authProvider.signOut();
                            if (context.mounted) context.go('/login');
                          }
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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
          if (index == 2) context.go('/history');
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EBE8)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(0.8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildProfileTile({required IconData icon, required String title, required String value, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3E12).withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF0F3E12), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.8))),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EBE8)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.8), height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
