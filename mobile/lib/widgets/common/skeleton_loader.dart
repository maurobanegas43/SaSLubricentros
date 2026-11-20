import 'package:flutter/material.dart';

/// Shimmer skeleton loader for loading states.
/// Use instead of CircularProgressIndicator for content placeholders.
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  const SkeletonLoader.line({
    super.key,
    double lineWidth = double.infinity,
    this.height = 16.0,
    this.borderRadius = 8.0,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  }) : width = lineWidth;

  const SkeletonLoader.circle({
    super.key,
    double size = 40.0,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  })  : width = size,
        height = size,
        borderRadius = size / 2;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ??
        (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0));
    final highlight = widget.highlightColor ??
        (isDark ? const Color(0xFF4A5568) : const Color(0xFFF7FAFC));

    return SizedBox(
      width: widget.width == double.infinity ? null : widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, __) {
          return ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: [
                (_animation.value - 0.5).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.5).clamp(0.0, 1.0),
              ],
            ).createShader(bounds),
            child: Container(
              width: widget.width == double.infinity ? double.infinity : null,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Compound skeleton that mimics a vehicle/appointment card layout.
class CardSkeleton extends StatelessWidget {
  final int lines;
  const CardSkeleton({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1F2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: const Color(0xFF2D3748)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SkeletonLoader.circle(size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(height: 18, width: 140),
                    SizedBox(height: 6),
                    SkeletonLoader(height: 12, width: 80),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < lines - 1; i++) ...[
            const SkeletonLoader.line(height: 14),
            const SizedBox(height: 8),
          ],
          const SkeletonLoader.line(height: 14, lineWidth: 200),
        ],
      ),
    );
  }
}
