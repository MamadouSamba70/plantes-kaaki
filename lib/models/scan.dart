import 'package:cloud_firestore/cloud_firestore.dart';

enum DiseaseSeverity { low, medium, high }

class ScanModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String disease;
  final double confidence; // from 0.0 to 1.0
  final DiseaseSeverity severity;
  final DateTime createdAt;

  ScanModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.createdAt,
  });

  // Convert to Map for backend insertion
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'disease': disease,
      'confidence': confidence,
      'severity': severity.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Model from Backend JSON response
  factory ScanModel.fromMap(Map<String, dynamic> map, [String? id]) {
    DiseaseSeverity parseSeverity(String? value) {
      switch (value?.toLowerCase()) {
        case 'high':
          return DiseaseSeverity.high;
        case 'medium':
          return DiseaseSeverity.medium;
        case 'low':
        default:
          return DiseaseSeverity.low;
      }
    }

    return ScanModel(
      id: id ?? map['id'] ?? '',
      userId: map['user_id'] ?? map['userId'] ?? '',
      imageUrl: map['image_url'] ?? map['imageUrl'] ?? '',
      disease: map['disease'] ?? 'Inconnu',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      severity: parseSeverity(map['severity']),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : map['createdAt'] != null && map['createdAt'] is String 
              ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  // Helper properties for treatment and description
  String get description {
    switch (disease.toLowerCase()) {
      case 'sigatoka noire':// black sigatoka
      case 'sigatoka':
        return 'Maladie fongique grave affectant les feuilles du bananier, provoquant des nécroses sombres et réduisant fortement la photosynthèse.';
      case 'flétrissement bactérien':// moko or bacterial wilt
      case 'moko':
        return 'Maladie bactérienne dévastatrice entraînant le flétrissement des feuilles et le pourrissement interne du pseudo-tronc.';
      case 'maladie de panama': // panama disease
      case 'panama':
        return 'Maladie causée par un champignon du sol (Fusarium) qui attaque les racines et bloque la circulation de la sève.';
      case 'sain':
      case 'feuille saine':
        return 'Feuille saine et vigoureuse. Aucun signe d\'infection fongique ou bactérienne détecté.';
      default:
        return 'Présence possible d\'anomalies ou de carences nutritionnelles à surveiller.';
    }
  }

  String get treatment {
    switch (disease.toLowerCase()) {
      case 'sigatoka noire':
      case 'sigatoka':
        return '• Effeuiller et brûler les feuilles gravement atteintes.\n'
            '• Améliorer le drainage et espacer les plants pour réduire l\'humidité.\n'
            '• Appliquer un fongicide biologique ou systémique homologué si l\'infection dépasse le seuil critique.';
      case 'flétrissement bactérien':
      case 'moko':
        return '• Mettre en quarantaine ou détruire le plant infecté par brûlage.\n'
            '• Désinfecter rigoureusement tous les outils de coupe avec de l\'alcool ou du chlore.\n'
            '• Contrôler les insectes vecteurs et utiliser des rejets certifiés sains.';
      case 'maladie de panama':
      case 'panama':
        return '• Cette maladie est incurable en terre. Il faut isoler la zone et ne pas planter de bananiers sensibles dans ce sol.\n'
            '• Utiliser des variétés de bananiers résistantes.\n'
            '• Éviter les transferts de sol ou d\'eau provenant de zones contaminées.';
      case 'sain':
      case 'feuille saine':
        return '• Continuer l\'irrigation et l\'apport de compost organique.\n'
            '• Inspecter régulièrement le champ, en particulier pendant la saison humide.';
      default:
        return '• Surveiller l\'évolution de la feuille.\n'
            '• Assurer une fertilisation équilibrée (Azote, Phosphore, Potassium).';
    }
  }
}
