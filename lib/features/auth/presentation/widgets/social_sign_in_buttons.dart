import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/snackbar.dart';
import '../../data/auth_error_mapper.dart';
import '../auth_controller.dart';

class SocialSignInButtons extends ConsumerWidget {
  const SocialSignInButtons({super.key});

  Future<void> _handle(
      BuildContext context,
      WidgetRef ref,
      Future<bool> Function(AuthController c) action,
      ) async {
    final success = await action(ref.read(authControllerProvider.notifier));
    if (success || !context.mounted) return;
    final error = ref.read(authControllerProvider).error;
    if (error != null) {
      showAppSnackBar(context, mapAuthError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: isLoading
              ? null
              : () => _handle(context, ref, (c) => c.signInWithGoogle()),
          icon: Image.asset('assets/images/google_logo.png', height: 20),
          label: const Text('Google ile devam et'),
        ),
        if (isIOS) ...[
          const SizedBox(height: AppConstants.paddingM),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: isLoading
                ? null
                : () => _handle(context, ref, (c) => c.signInWithApple()),
            icon: const Icon(Icons.apple),
            label: const Text('Apple ile devam et'),
          ),
        ],
      ],
    );
  }
}