import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_error_mapper.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const _cooldownSeconds = 60;
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _secondsLeft = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _check(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _secondsLeft = _cooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    _checking = true;
    try {
      final verified =
      await ref.read(authControllerProvider.notifier).checkEmailVerified();
      if (!verified && !silent && mounted) {
        showAppSnackBar(context, 'E-posta adresiniz henüz doğrulanmadı.',
            isError: true);
      }
    } catch (_) {
      if (!silent && mounted) {
        showAppSnackBar(context, 'Kontrol edilemedi, tekrar deneyin.',
            isError: true);
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _resend() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .resendVerificationEmail();
    if (!mounted) return;
    if (success) {
      showAppSnackBar(context, 'Doğrulama e-postası tekrar gönderildi.');
      setState(_startCooldown);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        showAppSnackBar(context, mapAuthError(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(authStateProvider).value?.email ?? '';
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('E-posta Doğrulama')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_unread_outlined,
                size: 88, color: AppColors.primary),
            const SizedBox(height: AppConstants.paddingL),
            Text('E-postanızı doğrulayın',
                textAlign: TextAlign.center, style: textTheme.headlineSmall),
            const SizedBox(height: AppConstants.paddingM),
            Text(
              '$email adresine bir doğrulama bağlantısı gönderdik. '
                  'Bağlantıya tıkladıktan sonra bu ekran kendiliğinden ilerleyecek.\n\n'
                  'E-postayı göremiyorsanız spam klasörünü kontrol edin.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppConstants.paddingL),
            PrimaryButton(
              label: 'Doğruladım, devam et',
              onPressed: () => _check(),
            ),
            const SizedBox(height: AppConstants.paddingM),
            TextButton(
              onPressed: _secondsLeft > 0 || isLoading ? null : _resend,
              child: Text(_secondsLeft > 0
                  ? 'Tekrar gönder ($_secondsLeft sn)'
                  : 'E-postayı tekrar gönder'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              child: const Text('Farklı bir hesapla giriş yap'),
            ),
          ],
        ),
      ),
    );
  }
}