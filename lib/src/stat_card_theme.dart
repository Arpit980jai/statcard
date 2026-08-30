import 'package:flutter/material.dart';

import 'models/stat_card_trend.dart';

/// Visual configuration for stat cards.
///
/// [StatCardThemeData] is a [ThemeExtension], so it can be registered globally
/// on a [ThemeData], supplied to a subtree with [StatCardTheme], or passed to a
/// single widget. Every field is nullable: unset fields fall back to
/// [StatCardThemeData.fallback], which derives sensible values from the ambient
/// [ColorScheme] and [TextTheme].
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const <ThemeExtension<dynamic>>[
///       StatCardThemeData(borderRadius: 24),
///     ],
///   ),
///   home: const Dashboard(),
/// );
/// ```
@immutable
class StatCardThemeData extends ThemeExtension<StatCardThemeData> {
  /// Creates a stat card theme. Every field is optional.
  const StatCardThemeData({
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.upColor,
    this.downColor,
    this.flatColor,
    this.skeletonBaseColor,
    this.sparklineColor,
    this.sparklineStrokeWidth,
    this.valueStyle,
    this.labelStyle,
    this.unitStyle,
    this.trendStyle,
    this.borderRadius,
    this.borderWidth,
    this.elevation,
    this.iconSize,
    this.spacing,
    this.padding,
  });

  /// Fill colour of the card surface.
  final Color? backgroundColor;

  /// Colour of the card border.
  final Color? borderColor;

  /// Colour applied to the card icon through [IconTheme].
  final Color? iconColor;

  /// Colour used by trend badges with [StatTrendDirection.up].
  final Color? upColor;

  /// Colour used by trend badges with [StatTrendDirection.down].
  final Color? downColor;

  /// Colour used by trend badges with [StatTrendDirection.flat].
  final Color? flatColor;

  /// Base colour of the pulsing bars shown while a card is loading.
  final Color? skeletonBaseColor;

  /// Stroke colour of the sparkline drawn under the label.
  ///
  /// ```dart
  /// const StatCardThemeData(sparklineColor: Color(0xFF3B6EF3));
  /// ```
  final Color? sparklineColor;

  /// Stroke width of the sparkline drawn under the label.
  ///
  /// ```dart
  /// const StatCardThemeData(sparklineStrokeWidth: 2);
  /// ```
  final double? sparklineStrokeWidth;

  /// Text style of the headline value.
  final TextStyle? valueStyle;

  /// Text style of the descriptive label under the value.
  final TextStyle? labelStyle;

  /// Text style of the small unit suffix rendered next to the value.
  final TextStyle? unitStyle;

  /// Text style used inside trend badges.
  final TextStyle? trendStyle;

  /// Corner radius of the card and of its ink splashes.
  final double? borderRadius;

  /// Stroke width of the card border. Use zero to remove the border.
  final double? borderWidth;

  /// Material elevation of the card surface.
  final double? elevation;

  /// Size of the card icon, applied through [IconTheme].
  final double? iconSize;

  /// Gap between the icon, the value, the label and the trend badge.
  final double? spacing;

  /// Inner padding of the card.
  final EdgeInsetsGeometry? padding;

  /// Builds a fully populated theme from the ambient [Theme].
  ///
  /// The result never contains a null field, which makes it usable as the
  /// bottom of the resolution chain. It works for Material 2 and Material 3, in
  /// both light and dark mode, with zero configuration.
  static StatCardThemeData fallback(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final isDark = colors.brightness == Brightness.dark;

    return StatCardThemeData(
      backgroundColor: colors.surfaceContainerHighest,
      borderColor: colors.outlineVariant,
      iconColor: colors.primary,
      upColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
      downColor: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
      flatColor: colors.onSurfaceVariant,
      skeletonBaseColor: colors.onSurface.withValues(alpha: 0.12),
      sparklineColor: colors.primary,
      sparklineStrokeWidth: 1.5,
      valueStyle: (text.headlineSmall ?? const TextStyle(fontSize: 24))
          .copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
      labelStyle: (text.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
        color: colors.onSurfaceVariant,
        height: 1.25,
      ),
      unitStyle: (text.titleSmall ?? const TextStyle(fontSize: 14)).copyWith(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      trendStyle: (text.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
        fontWeight: FontWeight.w600,
      ),
      borderRadius: 16,
      borderWidth: 1,
      elevation: 0,
      iconSize: 24,
      spacing: 8,
      padding: const EdgeInsets.all(16),
    );
  }

  /// Returns a copy of this theme where every field set on [other] wins.
  ///
  /// Fields that are null on [other] are inherited from this instance. That is
  /// what lets a partial theme, for example one that only sets [borderRadius],
  /// keep the fallback colours.
  StatCardThemeData merge(StatCardThemeData? other) {
    if (other == null) {
      return this;
    }
    return StatCardThemeData(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      iconColor: other.iconColor ?? iconColor,
      upColor: other.upColor ?? upColor,
      downColor: other.downColor ?? downColor,
      flatColor: other.flatColor ?? flatColor,
      skeletonBaseColor: other.skeletonBaseColor ?? skeletonBaseColor,
      sparklineColor: other.sparklineColor ?? sparklineColor,
      sparklineStrokeWidth: other.sparklineStrokeWidth ?? sparklineStrokeWidth,
      valueStyle: other.valueStyle ?? valueStyle,
      labelStyle: other.labelStyle ?? labelStyle,
      unitStyle: other.unitStyle ?? unitStyle,
      trendStyle: other.trendStyle ?? trendStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      borderWidth: other.borderWidth ?? borderWidth,
      elevation: other.elevation ?? elevation,
      iconSize: other.iconSize ?? iconSize,
      spacing: other.spacing ?? spacing,
      padding: other.padding ?? padding,
    );
  }

  /// Resolves the effective theme for a stat card.
  ///
  /// Precedence, from lowest to highest: [fallback], the [ThemeData]
  /// extension, the nearest [StatCardTheme] ancestor, and finally [override].
  /// The layers are merged field by field rather than replaced wholesale.
  static StatCardThemeData resolve(
    BuildContext context,
    StatCardThemeData? override,
  ) {
    return fallback(context)
        .merge(Theme.of(context).extension<StatCardThemeData>())
        .merge(StatCardTheme.maybeOf(context))
        .merge(override);
  }

  @override
  StatCardThemeData copyWith({
    Color? backgroundColor,
    Color? borderColor,
    Color? iconColor,
    Color? upColor,
    Color? downColor,
    Color? flatColor,
    Color? skeletonBaseColor,
    Color? sparklineColor,
    double? sparklineStrokeWidth,
    TextStyle? valueStyle,
    TextStyle? labelStyle,
    TextStyle? unitStyle,
    TextStyle? trendStyle,
    double? borderRadius,
    double? borderWidth,
    double? elevation,
    double? iconSize,
    double? spacing,
    EdgeInsetsGeometry? padding,
  }) {
    return StatCardThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      iconColor: iconColor ?? this.iconColor,
      upColor: upColor ?? this.upColor,
      downColor: downColor ?? this.downColor,
      flatColor: flatColor ?? this.flatColor,
      skeletonBaseColor: skeletonBaseColor ?? this.skeletonBaseColor,
      sparklineColor: sparklineColor ?? this.sparklineColor,
      sparklineStrokeWidth: sparklineStrokeWidth ?? this.sparklineStrokeWidth,
      valueStyle: valueStyle ?? this.valueStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      unitStyle: unitStyle ?? this.unitStyle,
      trendStyle: trendStyle ?? this.trendStyle,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      elevation: elevation ?? this.elevation,
      iconSize: iconSize ?? this.iconSize,
      spacing: spacing ?? this.spacing,
      padding: padding ?? this.padding,
    );
  }

  @override
  StatCardThemeData lerp(ThemeExtension<StatCardThemeData>? other, double t) {
    if (other is! StatCardThemeData) {
      return this;
    }
    return StatCardThemeData(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      iconColor: Color.lerp(iconColor, other.iconColor, t),
      upColor: Color.lerp(upColor, other.upColor, t),
      downColor: Color.lerp(downColor, other.downColor, t),
      flatColor: Color.lerp(flatColor, other.flatColor, t),
      skeletonBaseColor: Color.lerp(
        skeletonBaseColor,
        other.skeletonBaseColor,
        t,
      ),
      sparklineColor: Color.lerp(sparklineColor, other.sparklineColor, t),
      sparklineStrokeWidth: _lerpDouble(
        sparklineStrokeWidth,
        other.sparklineStrokeWidth,
        t,
      ),
      valueStyle: TextStyle.lerp(valueStyle, other.valueStyle, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      unitStyle: TextStyle.lerp(unitStyle, other.unitStyle, t),
      trendStyle: TextStyle.lerp(trendStyle, other.trendStyle, t),
      borderRadius: _lerpDouble(borderRadius, other.borderRadius, t),
      borderWidth: _lerpDouble(borderWidth, other.borderWidth, t),
      elevation: _lerpDouble(elevation, other.elevation, t),
      iconSize: _lerpDouble(iconSize, other.iconSize, t),
      spacing: _lerpDouble(spacing, other.spacing, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t),
    );
  }

  static double? _lerpDouble(double? a, double? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    final begin = a ?? b!;
    final end = b ?? a!;
    return begin + (end - begin) * t;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is StatCardThemeData &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.iconColor == iconColor &&
        other.upColor == upColor &&
        other.downColor == downColor &&
        other.flatColor == flatColor &&
        other.skeletonBaseColor == skeletonBaseColor &&
        other.sparklineColor == sparklineColor &&
        other.sparklineStrokeWidth == sparklineStrokeWidth &&
        other.valueStyle == valueStyle &&
        other.labelStyle == labelStyle &&
        other.unitStyle == unitStyle &&
        other.trendStyle == trendStyle &&
        other.borderRadius == borderRadius &&
        other.borderWidth == borderWidth &&
        other.elevation == elevation &&
        other.iconSize == iconSize &&
        other.spacing == spacing &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    borderColor,
    iconColor,
    upColor,
    downColor,
    flatColor,
    skeletonBaseColor,
    sparklineColor,
    sparklineStrokeWidth,
    valueStyle,
    labelStyle,
    unitStyle,
    trendStyle,
    borderRadius,
    borderWidth,
    elevation,
    iconSize,
    spacing,
    padding,
  ]);
}

/// Supplies a [StatCardThemeData] to every stat card below it in the tree.
///
/// This sits between the [ThemeData] extension and a per-widget override in the
/// resolution order, which makes it convenient to style one screen or one
/// section differently from the rest of the app.
///
/// ```dart
/// StatCardTheme(
///   data: const StatCardThemeData(borderRadius: 24, elevation: 2),
///   child: StatCardGrid(children: cards),
/// );
/// ```
class StatCardTheme extends InheritedWidget {
  /// Creates a scope that applies [data] to all descendant stat cards.
  const StatCardTheme({required this.data, required super.child, super.key});

  /// The theme applied to descendant stat cards.
  final StatCardThemeData data;

  /// Returns the data of the nearest [StatCardTheme] ancestor, or null when
  /// there is none.
  static StatCardThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<StatCardTheme>()?.data;
  }

  @override
  bool updateShouldNotify(StatCardTheme oldWidget) => data != oldWidget.data;
}
