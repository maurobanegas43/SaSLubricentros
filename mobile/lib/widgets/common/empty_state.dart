import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configurable empty state with icon, title, subtitle, and optional CTA.
///
/// Supports two visual styles:
/// - [EmptyStateStyle.standard]: Icon with subtle background circle
/// - [EmptyStateStyle.minimal]: Simple icon without background
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final double iconSize;
  final EmptyStateStyle style;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconSize = 80,
    this.style = EmptyStateStyle.standard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface.withValues(alpha: 0.25);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with optional background circle
            if (style == EmptyStateStyle.standard)
              Container(
                width: iconSize + 24,
                height: iconSize + 24,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
              )
            else
              Icon(icon, size: iconSize, color: iconColor),

            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),

            // Subtitle
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // CTA Button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onAction!();
                },
                icon: Icon(actionIcon ?? Icons.add, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Visual style for empty state icons.
enum EmptyStateStyle {
  /// Icon with subtle background circle (default)
  standard,

  /// Simple icon without background
  minimal,
}
