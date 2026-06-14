
/// Roles: farmer, agronomist, researcher, superadmin
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final bool isApproved;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.role = 'farmer',
    this.isApproved = false,
    required this.createdAt,
  });

  // Convert to Map for Backend insertion
  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'full_name': fullName,
      'email': email,
      'role': role,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create Model from Backend JSON response
  factory UserModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserModel(
      uid: id ?? map['id'] ?? map['uid'] ?? '',
      fullName: map['full_name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'farmer',
      isApproved: map['is_approved'] ?? map['isApproved'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : map['createdAt'] != null && map['createdAt'] is String 
              ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  /// Helper getters
  bool get isSuperAdmin => role == 'superadmin';
  bool get isFarmer => role == 'farmer';
  bool get isAgronomist => role == 'agronomist';
  bool get isResearcher => role == 'researcher';
  bool get isStudent => role == 'student';

  String get roleLabel {
    switch (role) {
      case 'superadmin':
        return 'Administrateur';
      case 'agronomist':
        return 'Agronome';
      case 'researcher':
        return 'Chercheur';
      case 'student':
        return 'Étudiant';
      case 'farmer':
      default:
        return 'Agriculteur';
    }
  }

  String get roleIcon => '';

  UserModel copyWith({bool? isApproved, String? role}) {
    return UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      createdAt: createdAt,
    );
  }
}
