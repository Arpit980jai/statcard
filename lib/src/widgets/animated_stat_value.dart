import 'package:flutter/widgets.dart';

/// Counts from the previous numeric value to the current one.
///
/// The builder is handed both ends of the animation as well as the current
/// frame's value. Callers measure the text against [from] and [to] — two fixed
/// strings — and only paint the interpolated one, so a running animation never
/// puts a new key into the measurement cache.
///
/// This class is internal to the package and is not exported.
class AnimatedStatValue extends StatefulWidget {
  /// Creates a widget that animates towards [value].
  const AnimatedStatValue({
    required this.value,
    required this.duration,
    required this.curve,
    required this.builder,
    super.key,
  });

  /// The target value.
  final num value;

  /// How long a change takes.
  final Duration duration;

  /// The easing applied to the count.
  final Curve curve;

  /// Builds the text for one frame.
  final Widget Function(BuildContext context, num from, num to, num current)
  builder;

  @override
  State<AnimatedStatValue> createState() => _AnimatedStatValueState();
}

class _AnimatedStatValueState extends State<AnimatedStatValue> {
  late num _from = widget.value;

  @override
  void didUpdateWidget(AnimatedStatValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value;
    }
  }

  /// Keeps an integer metric reading as an integer while it counts.
  num _quantise(double raw) {
    if (widget.value is int && _from is int) {
      return raw.round();
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion || widget.duration == Duration.zero) {
      // Nothing to interpolate: the target is both ends of the animation.
      return widget.builder(context, widget.value, widget.value, widget.value);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _from.toDouble(),
        end: widget.value.toDouble(),
      ),
      duration: widget.duration,
      curve: widget.curve,
      builder: (BuildContext context, double raw, Widget? _) {
        return widget.builder(context, _from, widget.value, _quantise(raw));
      },
    );
  }
}
