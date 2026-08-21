import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

/// The direction of a [StatTrend], used to pick a default colour and glyph.
enum StatTrendDirection {
  /// The metric increased since the previous period.
  up,

  /// The metric decreased since the previous period.
  down,

  /// The metric did not meaningfully change.
  flat,
}

/// An immutable description of the delta badge rendered inside a [StatCard].
///
/// ```dart
/// const StatCard(
///   value: '1,248',
///   label: 'Deliveries',
///   trend: StatTrend.up('+12.4%'),
/// );
/// ```
@immutable
class StatTrend {
  /// Creates a trend badge with an explicit [direction].
  const StatTrend({required this.label, required this.direction, this.color});

  /// Creates an upwards trend badge, coloured with the theme's up colour.
  const StatTrend.up(this.label, {this.color})
    : direction = StatTrendDirection.up;

  /// Creates a downwards trend badge, coloured with the theme's down colour.
  const StatTrend.down(this.label, {this.color})
    : direction = StatTrendDirection.down;

  /// Creates a neutral trend badge, coloured with the theme's flat colour.
  const StatTrend.flat(this.label, {this.color})
    : direction = StatTrendDirection.flat;

  /// The text shown inside the badge, for example `'+12.4%'`.
  final String label;

  /// Whether the metric went up, down, or stayed flat.
  final StatTrendDirection direction;

  /// Overrides the colour derived from [direction] and the resolved theme.
  final Color? color;

  /// Returns a copy of this trend with the given fields replaced.
  StatTrend copyWith({
    String? label,
    StatTrendDirection? direction,
    Color? color,
  }) {
    return StatTrend(
      label: label ?? this.label,
      direction: direction ?? this.direction,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is StatTrend &&
        other.label == label &&
        other.direction == direction &&
        other.color == color;
  }

  @override
  int get hashCode => Object.hash(label, direction, color);

  @override
  String toString() => 'StatTrend($label, $direction)';
}
