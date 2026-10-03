import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepository {
  ProfileRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const maxAvatarBytes = 200000;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _avatarDoc(String uid) =>
      _firestore.collection('userAvatars').doc(uid);

  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? phone,
    String? bloodType,
    List<String> allergies = const []
}) async {
    final cleanPhone = phone?.trim();
    await _doc(uid).update({
      'fullName': fullName.trim(),
      'phone': (cleanPhone == null || cleanPhone.isEmpty) ? null : cleanPhone,
      'bloodType': bloodType,
      'allergies': allergies,
    });
    await _auth.currentUser?.updateDisplayName(fullName.trim());
  }

  Future<void> uploadAvatar(String uid, XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > maxAvatarBytes) {
      throw Exception('Fotoğraf çok büyük');
    }
    await _avatarDoc(uid).set({
      'photo': base64Encode(bytes),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAvatar(String uid) => _avatarDoc(uid).delete();

  Stream<String?> watchAvatar(String uid) {
    return _avatarDoc(uid)
        .snapshots()
        .map((snap) => snap.data()?['photo'] as String?);
  }
}