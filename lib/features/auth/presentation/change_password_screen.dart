import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/auth_error_mapper.dart';
import 'auth_controller.dart';
import 'widgets/password_strength_indicator.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateNew(String? value) {
    final error = Validators.newPassword(value);
    if (error != null) return error;
    if (value == _currentController.text) {
      return 'Yeni şifre mevcut şifreden farklı olmalı.';
    }
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success =
    await ref.read(authControllerProvider.notifier).changePassword(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    );
    if (!mounted) return;

    if (success) {
      showAppSnackBar(context, 'Şifreniz başarıyla güncellendi.');
      context.pop();
    } else {
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
      appBar: AppBar(title: const Text('Şifre Değiştir')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _currentController,
                  label: 'Mevcut şifre',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.loginPassword,
                ),
                gap,
                AppTextField(
                  controller: _newController,
                  label: 'Yeni şifre',
                  icon: Icons.lock_reset,
                  isPassword: true,
                  validator: _validateNew,
                ),
                PasswordStrengthIndicator(controller: _newController),
                gap,
                AppTextField(
                  controller: _confirmController,
                  label: 'Yeni şifre (tekrar)',
                  icon: Icons.lock_reset,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                  v != _newController.text ? 'Şifreler eşleşmiyor.' : null,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppConstants.paddingL),
                PrimaryButton(
                  label: 'Şifreyi Güncelle',
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