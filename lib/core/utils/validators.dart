abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? notEmpty(String? value, {String field = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) return '$field boş bırakılamaz.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-posta gerekli.';
    if (!_emailRegex.hasMatch(value.trim())) return 'Geçerli bir e-posta girin.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli.';
    if (value.length < 6) return 'Şifre en az 6 karakter olmalı.';
    return null;
  }

  /// Telefon isteğe bağlı. Doluysa 05XX XXX XX XX formatında olmalı.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^0?5\d{9}$').hasMatch(digits)) {
      return 'Geçerli bir cep telefonu girin.';
    }
    return null;
  }
}