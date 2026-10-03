import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final avatarProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(authStateProvider.select((s) => s.value?.uid));
  if (uid == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchAvatar(uid);
});

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  String get _uid {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) throw StateError('Oturum bulunamadı');
    return uid;
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }

  Future<bool> uploadAvatar(XFile file) =>
      _run(() => _repo.uploadAvatar(_uid, file));

  Future<bool> removeAvatar() => _run(() => _repo.removeAvatar(_uid));

  Future<bool> updateProfile({
    required String fullName,
    String? phone,
    String? bloodType,
    List<String> allergies = const [],
  }) =>
      _run(() => _repo.updateProfile(
        uid: _uid,
        fullName: fullName,
        phone: phone,
        bloodType: bloodType,
        allergies: allergies,
      ));
}

final profileControllerProvider =
AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

String profileErrorMessage(Object? error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok.';
      case 'unavailable':
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'not-found':
        return 'Kayıt bulunamadı.';
    }
  }
  if (error.toString().contains('Fotoğraf çok büyük')) {
    return 'Fotoğraf çok büyük, daha küçük bir fotoğraf seçin.';
  }
  return 'Bir hata oluştu, tekrar deneyin.';
}