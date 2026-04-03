import 'package:flutter/material.dart';

/// Standard confirmation dialog with consistent styling.
/// Returns true if confirmed, false if cancelled.
class ConfirmationDialog {
  ConfirmationDialog._();

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: Text(cancelLabel)),
          FilledButton(
            onPressed: () => Navigator.pop(_, true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Theme.of(_).colorScheme.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
