import 'package:flutter/material.dart';

import 'stat_card.dart';

/// A responsive grid of [StatCard]s that reflows instead of overflowing.
///
/// The number of columns is derived from the available width and
/// [minCardWidth], so the same grid works from a 240 px phone to a 2000 px
/// desktop window without any breakpoint configuration.
///
/// ```dart
/// StatCardGrid(
///   minCardWidth: 180,
///   children: const <StatCard>[
///     StatCard(value: '1,248', label: 'Deliveries'),
///     StatCard(value: '₹4.2L', label: 'Revenue'),
///     StatCard(value: '312', label: 'Active users'),
///   ],
/// );
/// ```
class StatCardGrid extends StatelessWidget {
  /// Creates a responsive stat card grid.
  const StatCardGrid({
    required this.children,
    this.minCardWidth = 160,
    this.spacing = 12,
    this.runSpacing = 12,
    this.childAspectRatio,
    super.key,
  });

  /// The cards to lay out, in reading order.
  final List<StatCard> children;

  /// The narrowest a card may get before a column is dropped.
  ///
  /// Defaults to `160`.
  final double minCardWidth;

  /// Horizontal gap between cards. Defaults to `12`.
  final double spacing;

  /// Vertical gap between rows of cards. Defaults to `12`.
  final double runSpacing;

  /// When set, every card is forced to `width / height == childAspectRatio`.
  ///
  /// Leave it null to let each row size itself to its tallest card, which is
  /// the safest option for long labels and large text scales.
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite) {
          // No width to divide up; fall back to a plain wrap.
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            children: children,
          );
        }

        final columns = (maxWidth / minCardWidth).floor().clamp(
          1,
          children.length,
        );
        final totalSpacing = spacing * (columns - 1);
        // Never let rounding push the row past its constraints.
        final itemWidth = ((maxWidth - totalSpacing) / columns).clamp(
          0.0,
          maxWidth,
        );

        final ratio = childAspectRatio;
        if (ratio != null) {
          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: ratio,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: children,
          );
        }

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: <Widget>[
            for (final StatCard card in children)
              SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}
