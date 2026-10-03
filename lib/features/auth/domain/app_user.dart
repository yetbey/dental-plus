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
});

  final String uid;
  final String email;
  final String fullName;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String?,
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.patient,
      createdAt:
      (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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