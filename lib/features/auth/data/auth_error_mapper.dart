import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Kullanıcı Google veya Apple penceresini kendisi kapattıysa bu bir hata değildir.
bool isAuthCancellation(Object error) =>
    (error is GoogleSignInException &&
        error.code == GoogleSignInExceptionCode.canceled) ||
        (error is FirebaseAuthException &&
            (error.code == 'canceled' || error.code == 'web-context-canceled'));

String mapAuthError(Object error) {
  if (error is GoogleSignInException) return 'Google ile giriş başarısız oldu.';
  if (error is! FirebaseAuthException) {
    return 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
  }

  return switch (error.code) {
    'invalid-email' => 'Geçerli bir e-posta adresi girin.',
  // E-posta numaralandırma koruması açıkken Firebase üçünü de
  // 'invalid-credential' olarak döner. Mesaj bilerek genel tutuldu.
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' =>
    'E-posta veya şifre hatalı.',
    'email-already-in-use' => 'Bu e-posta adresi zaten kayıtlı.',
    'weak-password' =>
    'Şifre en az 8 karakter olmalı; büyük harf, küçük harf ve rakam içermeli.',
    'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
    'too-many-requests' =>
    'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.',
    'network-request-failed' => 'İnternet bağlantınızı kontrol edin.',
    'operation-not-allowed' => 'Bu giriş yöntemi şu anda kullanılamıyor.',
    'account-exists-with-different-credential' =>
    'Bu e-posta başka bir giriş yöntemiyle kayıtlı. Lütfen o yöntemle giriş yapın.',
    'requires-recent-login' => 'Güvenlik için lütfen tekrar giriş yapın.',
    _ => 'Bir hata oluştu. Lütfen tekrar deneyin.',
  };
}