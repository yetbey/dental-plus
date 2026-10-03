import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.health_and_safety_rounded,
                size: 96, color: AppColors.primary),
            const SizedBox(height: AppConstants.paddingM),
            Text(AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppConstants.paddingL),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}