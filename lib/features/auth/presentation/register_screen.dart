import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_error_mapper.dart';
import 'auth_controller.dart';
import 'widgets/password_strength_indicator.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _kvkkAccepted = false;

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _phoneController,
      _emailController,
      _passwordController,
      _confirmController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_kvkkAccepted) {
      showAppSnackBar(context, 'Devam etmek için KVKK metnini onaylayın.',
          isError: true);
      return;
    }

    final phone = _phoneController.text.trim();
    final success = await ref.read(authControllerProvider.notifier).signUp(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phone: phone.isEmpty ? null : phone,
    );

    if (!success && mounted) {
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        showAppSnackBar(context, mapAuthError(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    const gap = SizedBox(height: AppConstants.paddingM);

    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Ad Soyad',
                  icon: Icons.person_outline,
                  validator: (v) => Validators.notEmpty(v, field: 'Ad soyad'),
                ),
                gap,
                AppTextField(
                  controller: _phoneController,
                  label: 'Telefon (isteğe bağlı)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                gap,
                AppTextField(
                  controller: _emailController,
                  label: 'E-posta',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                gap,
                AppTextField(
                  controller: _passwordController,
                  label: 'Şifre',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.newPassword,
                ),
                PasswordStrengthIndicator(controller: _passwordController),
                gap,
                AppTextField(
                  controller: _confirmController,
                  label: 'Şifre (tekrar)',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _passwordController.text
                      ? 'Şifreler eşleşmiyor.'
                      : null,
                  onSubmitted: (_) => _submit(),
                ),
                CheckboxListTile(
                  value: _kvkkAccepted,
                  onChanged: (v) => setState(() => _kvkkAccepted = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Kişisel verilerimin KVKK kapsamında işlenmesini kabul ediyorum.',
                  ),
                ),
                gap,
                PrimaryButton(
                  label: 'Kayıt Ol',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}