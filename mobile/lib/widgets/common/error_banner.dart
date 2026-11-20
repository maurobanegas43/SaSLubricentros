import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// User-friendly error banner with retry action.
class ErrorBanner extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorBanner({
    super.key,
    required this.message,
    this.retryLabel,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.error.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(retryLabel ?? AppStrings.errorRetry),
              style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
            ),
          ],
        ],
      ),
    );
  }
}
