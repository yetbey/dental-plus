import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // Sadece bu widget yeniden çizilir, formun tamamı değil.
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final text = controller.text;
        if (text.isEmpty) return const SizedBox.shrink();

        final total = Validators.passwordRules.length;
        final score = Validators.passwordScore(text);
        final (label, color) = switch (score) {
          <= 2 => ('Zayıf', AppColors.error),
          3 => ('Orta', Colors.orange),
          _ => ('Güçlü', AppColors.success),
        };
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / total,
                  minHeight: 6,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Şifre gücü: $label',
                style: textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final rule in Validators.passwordRules)
                    _RuleItem(
                      label: rule.label,
                      passed: rule.pattern.hasMatch(text),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.label, required this.passed});

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          passed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}