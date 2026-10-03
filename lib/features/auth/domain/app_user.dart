import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { patient, admin }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.phone,
    this.bloodType,
    this.allergies = const [],
  });

  final String uid;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;
  final String? bloodType;
  final List<String> allergies;

  bool get isAdmin => role == UserRole.admin;

  String get protocolNo => 'DN-${uid.substring(0, 5).toUpperCase()}';

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.patient,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bloodType: map['bloodType'] as String?,
      allergies: ((map['allergies'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'role': role.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}