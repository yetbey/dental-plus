import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore, this._googleSignIn);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Future<void>? _googleInit;
  Future<void> _ensureGoogleInitialized() =>
  _googleInit ??= _googleSignIn.initialize();

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<User?> userChanges() => _auth.userChanges();

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(fullName);

    final appUser = AppUser(
      uid: user.uid,
      email: user.email!,
      fullName: fullName.trim(),
      phone: phone?.trim(),
      role: UserRole.patient,
      createdAt: DateTime.now(),
    );
    await _users.doc(user.uid).set(appUser.toMap());
  }

  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await _googleSignIn.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(result.user!);
  }

  Future<void> signInWithApple() async {
    final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
    final result = await _auth.signInWithProvider(provider);
    await _ensureUserDocument(result.user!);
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null) await _sendVerification(user);
  }

  Future<bool> reloadAndCheckVerified() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.emailVerified) await user.getIdToken(true);
    return user.emailVerified;
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {

    }
    await _auth.signOut();
  }

  Future<void> _sendVerification(User user) async {
    await _auth.setLanguageCode('tr');
    await user.sendEmailVerification();
  }

  Future<void> _ensureUserDocument(
      User user, {
        String? fullName,
        String? phone
  }) async {
    final doc = _users.doc(user.uid);
    try {
      if ((await doc.get()).exists) return;
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        fullName: (fullName ?? user.displayName ?? '').trim(),
        phone: phone?.trim(),
        role: UserRole.patient,
        createdAt: DateTime.now(),
      );
      await doc.set({
        ...appUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Stream<AppUser?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromMap(snap.data()!, snap.id) : null,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    GoogleSignIn.instance,
  );
});