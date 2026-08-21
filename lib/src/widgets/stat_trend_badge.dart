import 'package:flutter/material.dart';

import '../models/stat_card_trend.dart';
import '../stat_card_theme.dart';

/// The small delta chip rendered under a stat card value.
///
/// This class is internal to the package and is not exported.
class StatTrendBadge extends StatelessWidget {
  /// Creates a badge for [trend], coloured from [theme].
  const StatTrendBadge({required this.trend, required this.theme, super.key});

  /// The trend to display.
  final StatTrend trend;

  /// The already resolved stat card theme.
  final StatCardThemeData theme;

  IconData get _icon {
    switch (trend.direction) {
      case StatTrendDirection.up:
        return Icons.arrow_upward_rounded;
      case StatTrendDirection.down:
        return Icons.arrow_downward_rounded;
      case StatTrendDirection.flat:
        return Icons.trending_flat_rounded;
    }
  }

  Color _color(BuildContext context) {
    if (trend.color != null) {
      return trend.color!;
    }
    switch (trend.direction) {
      case StatTrendDirection.up:
        return theme.upColor ?? Theme.of(context).colorScheme.primary;
      case StatTrendDirection.down:
        return theme.downColor ?? Theme.of(context).colorScheme.error;
      case StatTrendDirection.flat:
        return theme.flatColor ??
            Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final style = (theme.trendStyle ?? const TextStyle(fontSize: 11)).copyWith(
      color: color,
    );
    final glyphSize = (style.fontSize ?? 11) + 2;

    // The chip has a hard minimum width: a glyph, a gap, the label and the
    // pill padding. In a very narrow card that minimum can exceed the space
    // available, so the whole chip is scaled down rather than allowed to
    // overflow. Nothing inside the row is flexible, which keeps it valid under
    // the unbounded constraints a FittedBox hands down.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(_icon, size: glyphSize, color: color),
            const SizedBox(width: 2),
            Text(
              trend.label,
              style: style,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
