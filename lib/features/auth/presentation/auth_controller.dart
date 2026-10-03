import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_error_mapper.dart';
import '../data/auth_repository.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) => _run(
    () => _repo.signUp(
      fullName: fullName,
      email: email,
      password: password,
      phone: phone,
    ),
  );

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _run(
    () => _repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  Future<void> deleteAccount({String? password}) =>
  _run(() => _repo.deleteAccount(password: password));

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _repo.sendPasswordReset(email));

  Future<void> signOut() => _repo.signOut();

  Future<bool> signInWithGoogle() => _run(_repo.signInWithGoogle);
  Future<bool> signInWithApple() => _run(_repo.signInWithApple);
  Future<bool> resendVerificationEmail() => _run(_repo.resendVerificationEmail);
  Future<bool> checkEmailVerified() => _repo.reloadAndCheckVerified();

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (result case AsyncError(:final error) when isAuthCancellation(error)) {
      state = const AsyncData(null);
      return false;
    }
    state = result;
    return !result.hasError;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
