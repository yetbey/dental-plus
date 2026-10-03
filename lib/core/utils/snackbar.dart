import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

void showAppSnackBar(
    BuildContext context,
    String message, {
      bool isError = false,
    }) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
}