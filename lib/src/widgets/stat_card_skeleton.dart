import 'package:flutter/material.dart';

import '../models/stat_card_layout.dart';
import 'safe_column.dart';

/// The pulsing placeholder rendered while a stat card is loading.
///
/// The pulse is a plain [AnimationController] driving an [Opacity]; the package
/// deliberately does not depend on a shimmer library. When the platform reports
/// that animations should be disabled, the bars are drawn statically.
///
/// This class is internal to the package and is not exported.
class StatCardSkeleton extends StatefulWidget {
  /// Creates a loading placeholder.
  const StatCardSkeleton({
    required this.baseColor,
    required this.spacing,
    required this.layout,
    required this.showIcon,
    required this.labelLines,
    this.iconSize = 24,
    super.key,
  });

  /// Fill colour of the placeholder bars.
  final Color baseColor;

  /// Vertical gap between bars.
  final double spacing;

  /// Layout being stood in for, so the icon block lands in the right place.
  final StatCardLayout layout;

  /// Whether an icon placeholder should be drawn.
  final bool showIcon;

  /// How many label bars to draw.
  final int labelLines;

  /// Edge length of the square icon placeholder.
  final double iconSize;

  @override
  State<StatCardSkeleton> createState() => _StatCardSkeletonState();
}

class _StatCardSkeletonState extends State<StatCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar(double widthFactor, double height) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: widget.baseColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final valueBar = textScaler.scale(20);
    final labelBar = textScaler.scale(10);

    final column = SafeColumn(
      children: <Widget>[
        _bar(0.6, valueBar),
        SizedBox(height: widget.spacing),
        for (var i = 0; i < widget.labelLines; i++) ...<Widget>[
          if (i > 0) SizedBox(height: widget.spacing / 2),
          _bar(i.isEven ? 1 : 0.7, labelBar),
        ],
      ],
    );

    final icon = Container(
      width: widget.iconSize,
      height: widget.iconSize,
      decoration: BoxDecoration(
        color: widget.baseColor,
        borderRadius: BorderRadius.circular(widget.iconSize / 4),
      ),
    );

    final Widget body;
    switch (widget.layout) {
      case StatCardLayout.noIcon:
        body = column;
      case StatCardLayout.iconAbove:
        body = SafeColumn(
          children: <Widget>[
            if (widget.showIcon) ...<Widget>[
              icon,
              SizedBox(height: widget.spacing),
            ],
            column,
          ],
        );
      case StatCardLayout.iconLeading:
        body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.showIcon) ...<Widget>[
              icon,
              SizedBox(width: widget.spacing),
            ],
            Expanded(child: column),
          ],
        );
      case StatCardLayout.iconTrailing:
        body = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: column),
            if (widget.showIcon) ...<Widget>[
              SizedBox(width: widget.spacing),
              icon,
            ],
          ],
        );
    }

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_controller),
      child: body,
    );
  }
}
