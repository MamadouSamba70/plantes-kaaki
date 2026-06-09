
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
    final name = disease.toLowerCase();
    if (name.contains('sigatoka')) {
      return 'Votre bananier montre des signes de Sigatoka noire sur ses feuilles. Ce champignon microscopique adore l\'humidité et crée ces taches sombres qui fatiguent la plante en l\'empêchant de bien respirer au soleil. Pas de panique, c\'est un défi fréquent mais tout à fait gérable.';
    } else if (name.contains('flétrissement') || name.contains('moko')) {
      return 'La tige présente des signes de flétrissement bactérien (souvent appelé Moko). C\'est une bactérie qui bloque la sève à l\'intérieur de la plante, ce qui fait plier ses feuilles comme si elle avait soif. Il faut agir vite et avec soin pour protéger le reste de votre champ.';
    } else if (name.contains('panama')) {
      return 'Votre bananier semble touché par la maladie de Panama. C\'est un champignon du sol (Fusarium) qui fatigue les racines et empêche la sève de monter dans la plante. C\'est un défi délicat qui demande des mesures de précaution pour préserver votre sol.';
    } else if (name.contains('pourriture') || name.contains('racine malade')) {
      return 'Les racines semblent souffrir de pourriture. Lorsque les racines sont fatiguées ou attaquées par un champignon du sol, la plante ne peut plus se nourrir correctement. C\'est comme si ses fondations étaient fragilisées.';
    } else if (name.contains('anthracnose')) {
      return 'Les fruits présentent des taches d\'anthracnose. C\'est un champignon très commun qui profite des petites blessures sur la peau des bananes pour s\'installer. Cela altère l\'aspect de vos fruits mais la plante elle-même reste forte.';
    } else if (name.contains('feuille saine')) {
      return 'Excellente nouvelle ! Cette feuille est magnifique, bien verte et vigoureuse. Elle capte parfaitement la lumière pour nourrir tout le bananier.';
    } else if (name.contains('fruit sain')) {
      return 'Vos fruits sont superbes et en parfaite santé ! La peau est propre et ils se développent de manière tout à fait naturelle.';
    } else if (name.contains('tige saine')) {
      return 'La tige (pseudo-tronc) est solide et saine. Elle soutient fièrement la plante et transporte bien la sève.';
    } else if (name.contains('racine saine')) {
      return 'Les racines sont saines et vigoureuses. Elles s\'ancrent profondément dans le sol pour puiser tous les nutriments.';
    } else if (name.contains('sain') || name.contains('saine')) {
      return 'Excellente nouvelle ! Cet organe est magnifique et en pleine santé. Aucun signe de maladie n\'a été détecté.';
    } else {
      return 'Nous avons détecté une anomalie légère ou une carence nutritionnelle. Parfois, un simple manque de nutriments dans le sol peut imiter une maladie.';
    }
  }

  String get treatment {
    final name = disease.toLowerCase();
    if (name.contains('sigatoka')) {
      return '• Prenez le temps de couper délicatement les feuilles les plus touchées et brûlez-les en dehors de la plantation pour stopper la propagation.\n'
          '• Éclaircissez un peu les plants autour pour laisser le vent circuler et sécher l\'humidité sur les feuilles.\n'
          '• Si besoin, appliquez un purin de plantes protecteur ou un traitement fongique adapté en début de matinée.';
    } else if (name.contains('flétrissement') || name.contains('moko')) {
      return '• Isolez rapidement le plant malade et détruisez-le pour éviter que la bactérie ne voyage vers les voisins.\n'
          '• C\'est crucial : désinfectez vos outils (coupe-coupe, machette) à l\'alcool ou au chlore après chaque coupe.\n'
          '• Contrôler les insectes qui aiment butiner les fleurs et utiliser des outils propres.';
    } else if (name.contains('panama')) {
      return '• Cette maladie est incurable en terre. Il faut isoler la zone et ne pas planter de bananiers sensibles dans ce sol.\n'
          '• Utiliser des variétés de bananiers résistantes.\n'
          '• Éviter les transferts de sol ou d\'eau provenant de zones contaminées.';
    } else if (name.contains('pourriture') || name.contains('racine malade')) {
      return '• Évitez absolument que l\'eau ne stagne autour du pied ; le bananier aime l\'eau mais déteste avoir les pieds noyés.\n'
          '• Apportez du compost bien mûr pour aider le sol à se défendre naturellement.\n'
          '• Si la zone est fort touchée, laissez reposer la terre ou changez de culture sur cette parcelle pour quelques temps.';
    } else if (name.contains('anthracnose')) {
      return '• Manipulez les régimes avec beaucoup de douceur lors de la récolte pour éviter les éraflures.\n'
          '• Nettoyez régulièrement la bananeraie en enlevant les débris de feuilles sèches qui abritent le champignon.\n'
          '• Vous pouvez protéger les jeunes régimes en les enveloppant dans des sacs de protection micro-perforés.';
    } else if (name.contains('feuille saine')) {
      return '• Continuez à veiller sur elle avec un bon arrosage régulier.\n'
          '• Un apport de compost au pied de temps en temps lui donnera toute la force nécessaire pour les prochains mois.';
    } else if (name.contains('fruit sain')) {
      return '• Protégez les régimes du soleil direct et des oiseaux si nécessaire.\n'
          '• Récoltez au bon moment pour préserver toute leur saveur.';
    } else if (name.contains('tige saine')) {
      return '• Veillez à ce que le sol reste meuble et riche autour du tronc.\n'
          '• Supprimez les vieux rejets inutiles pour concentrer toute l\'énergie sur la tige principale.';
    } else if (name.contains('racine saine')) {
      return '• Prenez soin de ne pas blesser les racines superficielles lors du désherbage.\n'
          '• Paillez le sol pour garder la fraîcheur et protéger les racines de la chaleur.';
    } else if (name.contains('sain') || name.contains('saine')) {
      return '• Continuez l\'entretien régulier de votre culture (arrosage, apport de compost).\n'
          '• Inspectez régulièrement le champ, en particulier pendant la saison humide.';
    } else {
      return '• Surveiller l\'évolution de la feuille.\n'
          '• Assurer une fertilisation équilibrée (Azote, Phosphore, Potassium).';
    }
  }

  /// Convertit l'enum DiseaseSeverity en libellé lisible
  String get severityLabel {
    switch (severity) {
      case DiseaseSeverity.high:
        return 'Élevée';
      case DiseaseSeverity.medium:
        return 'Modérée';
      case DiseaseSeverity.low:
        return 'Faible';
    }
  }

  /// Valeur brute de l'enum en minuscule (ex: 'high', 'medium', 'low')
  String get severityRaw => severity.toString().split('.').last;

  /// Vrai si la sévérité est haute
  bool get isHighSeverity => severity == DiseaseSeverity.high;
}
