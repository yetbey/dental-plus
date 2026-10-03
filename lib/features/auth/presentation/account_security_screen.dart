import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar.dart';
import '../data/auth_error_mapper.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() =>
      _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    final hasPassword = ref.read(hasPasswordProvider);

    // null: kullanıcı vazgeçti. Şifresiz hesaplarda boş string döner.
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(requiresPassword: hasPassword),
    );
    if (password == null || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount(
        password: hasPassword ? password : null,
      );
      // Auth durumu değişince router kullanıcıyı login ekranına yönlendirir.
    } catch (e) {
      if (!mounted || isAuthCancellation(e)) return;
      showAppSnackBar(context, mapAuthError(e), isError: true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = ref.watch(hasPasswordProvider);
    final email = ref.watch(authStateProvider).value?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Hesap ve Güvenlik')),
      body: AbsorbPointer(
        absorbing: _isDeleting,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          children: [
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('E-posta'),
              subtitle: Text(email),
            ),
            const Divider(),
            if (hasPassword)
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Şifreyi değiştir'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.changePassword),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Çıkış yap'),
              onTap: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
            const Divider(),
            ListTile(
              leading: _isDeleting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.delete_forever, color: AppColors.error),
              title: const Text(
                'Hesabı kalıcı olarak sil',
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text(
                'Profiliniz ve tüm verileriniz silinir. Bu işlem geri alınamaz.',
              ),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.requiresPassword});

  final bool requiresPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (widget.requiresPassword && _passwordController.text.isEmpty) return;
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hesabı sil'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.requiresPassword
                ? 'Devam etmek için mevcut şifrenizi girin.'
                : 'Kimliğinizi doğrulamak için hesap sağlayıcınızın penceresi açılacak.',
          ),
          if (widget.requiresPassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              autofocus: true,
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _confirm,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Kalıcı olarak sil'),
        ),
      ],
    );
  }
}