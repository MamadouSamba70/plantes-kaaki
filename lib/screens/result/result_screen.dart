import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/scan_provider.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final result = scanProvider.lastResult;
    final image = scanProvider.selectedImage;

    // Handle missing results gracefully
    if (result == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
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
          title: const Text('Erreur', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54, color: AppColors.danger),
              const SizedBox(height: 16),
              const Text('Aucun résultat de diagnostic disponible.'),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.go('/home'),
                child: const Text('Retour au Dashboard'),
              )
            ],
          ),
        ),
      );
    }

    // Determine visual markers based on severity (Muted classy tones)
    Color severityColor = const Color(0xFF0F3E12); // Forest Green
    String severityLabel = 'Faible';
    IconData severityIcon = Icons.check_circle_outline_rounded;

    if (result.disease.toLowerCase() != 'feuille saine') {
      final severityName = result.severity.toString().split('.').last;
      if (severityName == 'high') {
        severityColor = const Color(0xFFC62828); // Sourd red
        severityLabel = 'Élevée';
        severityIcon = Icons.dangerous_outlined;
      } else {
        severityColor = const Color(0xFFE5A93C); // Warm ochre
        severityLabel = 'Moyenne';
        severityIcon = Icons.warning_amber_outlined;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background, // Ivory background
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              scanProvider.clearImage();
              context.go('/home');
            },
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
          'Résultat Diagnostic',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image card preview
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EBE8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: image != null
                    ? Image.file(image, fit: BoxFit.cover)
                    : (result.imageUrl.isNotEmpty
                        ? Image.network(
                            result.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF0F3E12).withOpacity(0.06),
                              child: const Icon(Icons.image_outlined, size: 48, color: Color(0xFF0F3E12)),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF0F3E12).withOpacity(0.06),
                            child: const Icon(Icons.image_outlined, size: 48, color: Color(0xFF0F3E12)),
                          )),
              ),
            ),
            const SizedBox(height: 24),

            // Diagnostic Results Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EBE8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease Name
                  Text(
                    result.disease,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F3E12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Badges Row (Severity and Confidence)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Severity badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: severityColor.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(severityIcon, color: severityColor, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Gravité: $severityLabel',
                              style: TextStyle(
                                color: severityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Confidence Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3E12).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF0F3E12).withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.analytics_outlined, color: Color(0xFF0F3E12), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Fiabilité: ${(result.confidence * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF0F3E12),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Confidence bar graphic
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Indice de confiance IA', style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withOpacity(0.8))),
                          Text('${(result.confidence * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F3E12))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: result.confidence,
                          backgroundColor: const Color(0xFF0F3E12).withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(severityColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description details card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EBE8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'À propos de cette anomalie',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Treatment recommendations card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EBE8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Traitements recommandés',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result.treatment,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Quick Actions bottom buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                scanProvider.clearImage();
                context.go('/scan');
              },
              child: const Text('Scanner une autre feuille', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                scanProvider.clearImage();
                context.go('/home');
              },
              child: const Text(
                'Retour au Dashboard',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
