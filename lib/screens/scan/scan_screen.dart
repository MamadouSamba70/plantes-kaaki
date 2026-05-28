import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/scan_provider.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerAnimationController;

  @override
  void initState() {
    super.initState();
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user?.isSuperAdmin == true) {
        context.go('/admin');
      }
    });
  }

  @override
  void dispose() {
    _scannerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);
    await scanProvider.pickImage(source);
  }

  Future<void> _startDiagnostic() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous reconnecter.')),
      );
      return;
    }

    _scannerAnimationController.repeat(reverse: true);

    final result = await scanProvider.scanLeaf(authProvider.user!.uid);

    _scannerAnimationController.stop();

    if (result != null && mounted) {
      context.push('/result');
    } else if (scanProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scanProvider.errorMessage!),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final image = scanProvider.selectedImage;

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
          'Scanner une Feuille',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (image != null && !scanProvider.isScanning)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F3E12)),
              onPressed: scanProvider.clearImage,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Card / Guidance Dotted Box
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8EBE8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.01),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: image == null
                      ? _buildGuidanceView()
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(image, fit: BoxFit.cover),
                            if (scanProvider.isScanning)
                              AnimatedBuilder(
                                animation: _scannerAnimationController,
                                builder: (context, child) {
                                  return Positioned(
                                    top: _scannerAnimationController.value * MediaQuery.of(context).size.height * 0.45,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F3E12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0F3E12).withOpacity(0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            if (scanProvider.isScanning)
                              Container(
                                color: Colors.black.withOpacity(0.4),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: const CircularProgressIndicator(
                                          color: Color(0xFF0F3E12),
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Analyse en cours par l\'IA...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Control Buttons
            if (image == null)
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: 'Galerie',
                      icon: Icons.photo_library_outlined,
                      onPressed: () => _pickImage(ImageSource.gallery),
                      isPrimary: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Appareil',
                      icon: Icons.camera_alt_outlined,
                      onPressed: () => _pickImage(ImageSource.camera),
                      isPrimary: true,
                    ),
                  ),
                ],
              )
            else if (!scanProvider.isScanning)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3E12),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Lancer le Diagnostic', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _startDiagnostic,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: scanProvider.clearImage,
                    child: const Text(
                      'Annuler et changer d\'image',
                      style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
          if (index == 2) context.go('/history');
          if (index == 3) context.go('/profile');
        },
      ),
    );
  }

  Widget _buildGuidanceView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3E12).withOpacity(0.04),
              border: Border.all(
                color: const Color(0xFF0F3E12).withOpacity(0.15),
                width: 1.5,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.center_focus_weak_rounded,
              size: 54,
              color: Color(0xFF0F3E12),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cadrage de la feuille',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prenez une photo nette sous une bonne lumière, centrée sur la partie suspecte de la feuille de bananier.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? const Color(0xFF0F3E12) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF0F3E12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFFE8EBE8), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: onPressed,
    );
  }
}
