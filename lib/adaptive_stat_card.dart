/// Overflow-safe dashboard stat cards for Flutter, with zero runtime
/// dependencies.
///
/// The entry point is [StatCard]: a big value, a descriptive label, and an
/// optional icon, unit and trend badge. Its text is measured against the real
/// constraints and the ambient text scaler, so it degrades according to a
/// configurable [StatCardOverflow] strategy instead of throwing a layout
/// overflow.
///
/// ```dart
/// import 'package:adaptive_stat_card/adaptive_stat_card.dart';
///
/// StatCard(
///   value: '1,248',
///   label: 'Deliveries this month',
///   icon: const Icon(Icons.local_shipping_outlined),
///   trend: const StatTrend.up('+12.4%'),
/// );
/// ```
library;

export 'src/models/stat_card_layout.dart';
export 'src/models/stat_card_overflow.dart';
export 'src/models/stat_card_trend.dart';
export 'src/stat_card.dart';
export 'src/stat_card_grid.dart';
export 'src/stat_card_theme.dart';
