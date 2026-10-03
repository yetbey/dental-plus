import 'package:firebase_auth/firebase_auth.dart';

/// Firebase hata kodlarını kullanıcıya gösterilecek mesajlara çevirir.
String mapAuthError(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }
  return switch (error.code) {
    'invalid-email' => 'Geçersiz e-posta adresi.',
    'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' =>
    'E-posta veya şifre hatalı.',
    'email-already-in-use' => 'Bu e-posta adresi zaten kayıtlı.',
    'weak-password' => 'Şifre en az 6 karakter olmalı.',
    'too-many-requests' =>
    'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.',
    'network-request-failed' => 'İnternet bağlantınızı kontrol edin.',
    _ => 'Bir hata oluştu: ${error.message}',
  };
}