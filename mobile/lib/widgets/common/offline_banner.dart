import 'package:flutter/material.dart';

/// Non-blocking banner that appears when the device is offline.
/// Slides down from the top of the screen.
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final Widget child;

  const OfflineBanner({super.key, required this.isOffline, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOffline ? 32 : 0,
          child: isOffline
              ? Container(
                  width: double.infinity,
                  color: Colors.orange.shade700,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(width: 8),
                      Text(
                        'Sin conexión a internet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
        Expanded(child: child),
      ],
    );
  }
}
