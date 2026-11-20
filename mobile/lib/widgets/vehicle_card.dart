import 'package:flutter/material.dart';
import '../models/vehicle.dart';

/// Vehicle card with tap scale animation and Hero transitions.
///
/// Uses [AnimatedContainer] for subtle scale feedback on tap,
/// and [Hero] widgets for smooth transitions to the detail screen.
class VehicleCard extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback? onTap;
  final int? proximoServiceKm;

  const VehicleCard({
    super.key,
    required this.vehicle,
    this.onTap,
    this.proximoServiceKm,
  });

  @override
  State<VehicleCard> createState() => _VehicleCardState();
}

class _VehicleCardState extends State<VehicleCard> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    // Delay the navigation slightly so the user sees the release animation
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) widget.onTap?.call();
    });
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  double _calculateProgress() {
    if (widget.proximoServiceKm == null) return 0;
    final kmSinceLastService = widget.vehicle.kmActual;
    final totalKmInterval = widget.proximoServiceKm!;
    return (kmSinceLastService / totalKmInterval).clamp(0.0, 1.0);
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.7) return Colors.green;
    if (progress < 0.9) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Hero animation target — transitions to detail screen icon
                    Hero(
                      tag: 'vehicle-icon-${widget.vehicle.id}',
                      child: widget.vehicle.hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.vehicle.imageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.directions_car,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.directions_car,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero animation target — transitions to detail screen title
                          Hero(
                            tag: 'vehicle-name-${widget.vehicle.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                widget.vehicle.displayName,
                                style: theme.textTheme.headlineMedium,
                              ),
                            ),
                          ),
                          if (widget.vehicle.motor != null)
                            Text(
                              'Motor ${widget.vehicle.motor}',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.speed,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.vehicle.kmActual.toString()} km',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                if (widget.proximoServiceKm != null) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.1),
                    color: _getProgressColor(progress),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Próximo service: ${widget.proximoServiceKm} km',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
