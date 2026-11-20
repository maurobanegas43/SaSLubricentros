import 'package:flutter/material.dart';

/// Enum for loading spinner size variants
enum LoadingSize {
  small,
  medium,
  large,
}

/// Enum for loading spinner visual variants
enum LoadingVariant {
  spinner,
  dots,
  bar,
}

/// A reusable loading spinner widget with multiple variants and sizes
class LoadingSpinner extends StatelessWidget {
  final LoadingSize size;
  final LoadingVariant variant;
  final String? message;
  final Color? color;

  const LoadingSpinner({
    super.key,
    this.size = LoadingSize.medium,
    this.variant = LoadingVariant.spinner,
    this.message,
    this.color,
  });

  /// Get the dimension based on size
  double get _dimension {
    switch (size) {
      case LoadingSize.small:
        return 24.0;
      case LoadingSize.medium:
        return 40.0;
      case LoadingSize.large:
        return 56.0;
    }
  }

  /// Get the stroke width based on size
  double get _strokeWidth {
    switch (size) {
      case LoadingSize.small:
        return 2.0;
      case LoadingSize.medium:
        return 3.0;
      case LoadingSize.large:
        return 4.0;
    }
  }

  /// Get the message font size based on size
  double get _messageFontSize {
    switch (size) {
      case LoadingSize.small:
        return 12.0;
      case LoadingSize.medium:
        return 14.0;
      case LoadingSize.large:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVariant(context, effectiveColor),
        if (message != null) ...[
          SizedBox(height: size == LoadingSize.small ? 8.0 : 12.0),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: _messageFontSize,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildVariant(BuildContext context, Color effectiveColor) {
    switch (variant) {
      case LoadingVariant.spinner:
        return _SpinnerVariant(
          dimension: _dimension,
          strokeWidth: _strokeWidth,
          color: effectiveColor,
        );
      case LoadingVariant.dots:
        return _DotsVariant(
          dimension: _dimension,
          color: effectiveColor,
        );
      case LoadingVariant.bar:
        return _BarVariant(
          dimension: _dimension,
          color: effectiveColor,
        );
    }
  }
}

/// Circular spinner variant with rotation animation
class _SpinnerVariant extends StatefulWidget {
  final double dimension;
  final double strokeWidth;
  final Color color;

  const _SpinnerVariant({
    required this.dimension,
    required this.strokeWidth,
    required this.color,
  });

  @override
  State<_SpinnerVariant> createState() => _SpinnerVariantState();
}

class _SpinnerVariantState extends State<_SpinnerVariant>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.dimension,
      height: widget.dimension,
      child: CircularProgressIndicator(
        strokeWidth: widget.strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(widget.color),
      ),
    );
  }
}

/// Animated dots variant with sequential fade animation
class _DotsVariant extends StatefulWidget {
  final double dimension;
  final Color color;

  const _DotsVariant({
    required this.dimension,
    required this.color,
  });

  @override
  State<_DotsVariant> createState() => _DotsVariantState();
}

class _DotsVariantState extends State<_DotsVariant>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.dimension / 5;
    final spacing = dotSize * 0.8;

    return SizedBox(
      width: widget.dimension,
      height: dotSize,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final value = (_controller.value - delay) % 1.0;
              final opacity = _calculateDotOpacity(value);

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : spacing / 2,
                  right: index == 2 ? 0 : spacing / 2,
                ),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  double _calculateDotOpacity(double value) {
    if (value < 0.5) {
      return 0.3 + (value * 1.4);
    } else {
      return 1.0 - ((value - 0.5) * 1.4);
    }
  }
}

/// Horizontal bar variant with sliding animation
class _BarVariant extends StatefulWidget {
  final double dimension;
  final Color color;

  const _BarVariant({
    required this.dimension,
    required this.color,
  });

  @override
  State<_BarVariant> createState() => _BarVariantState();
}

class _BarVariantState extends State<_BarVariant>
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

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barHeight = widget.dimension / 6;
    final barWidth = widget.dimension * 2;

    return SizedBox(
      width: barWidth,
      height: barHeight,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(barHeight / 2),
            child: Stack(
              children: [
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(barHeight / 2),
                  ),
                ),
                Positioned(
                  left: _animation.value * (barWidth - barWidth * 0.4),
                  child: Container(
                    width: barWidth * 0.4,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(barHeight / 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
