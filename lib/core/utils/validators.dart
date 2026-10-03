/// Şifre kuralı: ekranda görünen kısa etiket, hata mesajı ve kontrol deseni.
typedef PasswordRule = ({String label, String error, RegExp pattern});

abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static final List<PasswordRule> passwordRules = [
    (
    label: 'En az 8 karakter',
    error: 'Şifre en az 8 karakter olmalı.',
    pattern: RegExp(r'^.{8,}$'),
    ),
    (
    label: 'Büyük harf',
    error: 'En az bir büyük harf içermeli.',
    pattern: RegExp(r'[A-ZÇĞİÖŞÜ]'),
    ),
    (
    label: 'Küçük harf',
    error: 'En az bir küçük harf içermeli.',
    pattern: RegExp(r'[a-zçğıöşü]'),
    ),
    (
    label: 'Rakam',
    error: 'En az bir rakam içermeli.',
    pattern: RegExp(r'\d'),
    ),
  ];

  /// Şifrenin kaç kuralı geçtiğini döner (0 ile passwordRules.length arası).
  static int passwordScore(String value) =>
      passwordRules.where((r) => r.pattern.hasMatch(value)).length;

  static String? notEmpty(String? value, {String field = 'Bu alan'}) {
    if (value == null || value.trim().isEmpty) return '$field boş bırakılamaz.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-posta gerekli.';
    if (!_emailRegex.hasMatch(value.trim())) return 'Geçerli bir e-posta girin.';
    return null;
  }

  /// Girişte sadece boşluk kontrolü yapılır. Kural ileride değişirse
  /// eski şifreli hesaplar giriş yapamaz hale gelmesin.
  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Şifre gerekli.' : null;

  /// Kayıtta ve şifre değiştirmede kullanılır.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli.';
    for (final rule in passwordRules) {
      if (!rule.pattern.hasMatch(value)) return rule.error;
    }
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