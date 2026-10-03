import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/snackbar.dart';
import '../data/auth_error_mapper.dart';
import 'auth_controller.dart';
import 'auth_providers.dart';

class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  Future<void> _deleteAccount(
      BuildContext context,
      WidgetRef ref,
      bool needsPassword,
      ) async {
    // null: vazgeçildi. Sosyal girişte boş metin döner.
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteAccountDialog(needsPassword: needsPassword),
    );
    if (password == null) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: needsPassword ? password : null);
    // Başarılıysa oturum kapanır ve router kullanıcıyı giriş ekranına götürür.
    if (success || !context.mounted) return;

    final error = ref.read(authControllerProvider).error;
    if (error != null) {
      showAppSnackBar(context, mapAuthError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPassword = ref.watch(hasPasswordProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final email = ref.watch(authStateProvider).value?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Hesap ve Güvenlik')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingM),
        children: [
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('E-posta'),
            subtitle: Text(email),
          ),
          if (hasPassword)
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Şifre değiştir'),
              trailing: const Icon(Icons.chevron_right),
              enabled: !isLoading,
              onTap: () => context.push(AppRoutes.changePassword),
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış yap'),
            enabled: !isLoading,
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const Divider(height: AppConstants.paddingL * 2),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Hesabı sil',
                style: TextStyle(color: AppColors.error)),
            subtitle: const Text(
                'Hesabınız ve kişisel verileriniz kalıcı olarak silinir.'),
            trailing: isLoading
                ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : null,
            enabled: !isLoading,
            onTap: () => _deleteAccount(context, ref, hasPassword),
          ),
        ],
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.needsPassword});

  final bool needsPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _confirmed &&
        (!widget.needsPassword || _passwordController.text.isNotEmpty);

    return AlertDialog(
      title: const Text('Hesabı sil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bu işlem geri alınamaz. Profiliniz ve hesabınız kalıcı olarak silinir.',
            ),
            const SizedBox(height: AppConstants.paddingM),
            if (widget.needsPassword)
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifreniz'),
                onChanged: (_) => setState(() {}),
              )
            else
              const Text(
                'Devam ettiğinizde güvenlik için hesabınızı tekrar seçmeniz istenecek.',
              ),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Hesabımın kalıcı olarak silineceğini anlıyorum.'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: canDelete
              ? () => Navigator.pop(context, _passwordController.text)
              : null,
          child: const Text('Hesabı sil'),
        ),
      ],
    );
  }
}