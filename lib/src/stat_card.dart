import 'package:flutter/material.dart';

import 'models/stat_card_layout.dart';
import 'models/stat_card_overflow.dart';
import 'models/stat_card_trend.dart';
import 'stat_card_theme.dart';
import 'widgets/adaptive_text.dart';
import 'widgets/safe_column.dart';
import 'widgets/stat_card_skeleton.dart';
import 'widgets/stat_trend_badge.dart';

/// A dashboard statistic card that never overflows.
///
/// A stat card shows one big [value], a descriptive [label], and optionally an
/// [icon], a [unit] suffix and a [trend] badge. Both texts are laid out by an
/// internal measurement engine that respects the ambient text scaler, so long
/// labels, translated strings, big numbers and accessibility text scaling all
/// degrade according to [overflow] instead of throwing a layout overflow.
///
/// ```dart
/// StatCard(
///   value: '1,248',
///   label: 'Deliveries this month',
///   unit: 'pkg',
///   icon: const Icon(Icons.local_shipping_outlined),
///   trend: const StatTrend.up('+12.4%'),
///   onTap: () => context.go('/deliveries'),
/// );
/// ```
///
/// See also:
///
///  * [StatCardOverflow], for the available degradation strategies.
///  * [StatCardLayout], for icon placement.
///  * [StatCardThemeData], for styling.
class StatCard extends StatelessWidget {
  /// Creates a stat card.
  const StatCard({
    required this.value,
    required this.label,
    this.icon,
    this.unit,
    this.trend,
    this.overflow = StatCardOverflow.shrinkThenWrap,
    this.layout = StatCardLayout.iconLeading,
    this.labelMaxLines = 2,
    this.valueMaxLines = 1,
    this.minFontScale = 0.7,
    this.onTap,
    this.isLoading = false,
    this.theme,
    this.semanticsLabel,
    this.padding,
    super.key,
  }) : _dense = false;

  /// Creates a dense stat card for tight dashboards.
  ///
  /// Compared to the default constructor this preset uses tighter padding, a
  /// single line label, and [StatCardOverflow.ellipsis].
  ///
  /// ```dart
  /// const StatCard.compact(value: '42', label: 'Open tickets');
  /// ```
  const StatCard.compact({
    required this.value,
    required this.label,
    this.icon,
    this.unit,
    this.trend,
    this.overflow = StatCardOverflow.ellipsis,
    this.layout = StatCardLayout.iconLeading,
    this.valueMaxLines = 1,
    this.minFontScale = 0.7,
    this.onTap,
    this.isLoading = false,
    this.theme,
    this.semanticsLabel,
    this.padding,
    super.key,
  }) : labelMaxLines = 1,
       _dense = true;

  /// Creates a card that only renders the loading skeleton.
  ///
  /// Use it while the metric is still being fetched; no value or label is
  /// required.
  ///
  /// ```dart
  /// const StatCard.loading();
  /// ```
  const StatCard.loading({
    this.icon,
    this.layout = StatCardLayout.iconLeading,
    this.labelMaxLines = 2,
    this.theme,
    this.padding,
    super.key,
  }) : value = '',
       label = '',
       unit = null,
       trend = null,
       overflow = StatCardOverflow.shrinkThenWrap,
       valueMaxLines = 1,
       minFontScale = 0.7,
       onTap = null,
       isLoading = true,
       semanticsLabel = null,
       _dense = false;

  /// The headline number, already formatted for display, such as `'1,248'`.
  final String value;

  /// The descriptive text under the value, such as `'Deliveries this month'`.
  final String label;

  /// An optional leading widget, typically an [Icon] or a small image.
  final Widget? icon;

  /// An optional short suffix rendered next to [value], such as `'kg'`.
  final String? unit;

  /// An optional delta badge rendered under the label.
  final StatTrend? trend;

  /// How the value and label degrade when they do not fit.
  ///
  /// Defaults to [StatCardOverflow.shrinkThenWrap].
  final StatCardOverflow overflow;

  /// Where the icon sits relative to the text.
  ///
  /// Defaults to [StatCardLayout.iconLeading].
  final StatCardLayout layout;

  /// The maximum number of lines the label may occupy. Defaults to `2`.
  final int labelMaxLines;

  /// The maximum number of lines the value may occupy. Defaults to `1`.
  final int valueMaxLines;

  /// The floor for shrinking strategies, as a fraction of the base font size.
  ///
  /// Defaults to `0.7`.
  final double minFontScale;

  /// Called when the card is tapped.
  ///
  /// When null, the card is not wrapped in an [InkWell] at all.
  final VoidCallback? onTap;

  /// Whether to render the loading skeleton instead of the content.
  final bool isLoading;

  /// A per-instance theme override, the highest priority theming layer.
  final StatCardThemeData? theme;

  /// Overrides the automatically generated accessibility label.
  ///
  /// The default reads as `'<label>: <value><unit>'`.
  final String? semanticsLabel;

  /// Overrides the inner padding coming from the resolved theme.
  final EdgeInsetsGeometry? padding;

  /// Whether this card came from the [StatCard.compact] preset.
  final bool _dense;

  @override
  Widget build(BuildContext context) {
    final resolved = StatCardThemeData.resolve(context, theme);
    final radius = BorderRadius.circular(resolved.borderRadius ?? 16);
    final spacing = (resolved.spacing ?? 8) * (_dense ? 0.75 : 1.0);
    final borderWidth = resolved.borderWidth ?? 1;
    final effectivePadding =
        padding ??
        (_dense
            ? const EdgeInsetsDirectional.all(10)
            : (resolved.padding ?? const EdgeInsets.all(16)));

    final content = isLoading
        ? _buildSkeleton(resolved, spacing)
        : _buildContent(context, resolved, spacing);

    Widget inner = Padding(padding: effectivePadding, child: content);
    if (onTap != null) {
      inner = InkWell(onTap: onTap, borderRadius: radius, child: inner);
    }

    final card = Material(
      color: resolved.backgroundColor,
      elevation: resolved.elevation ?? 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: borderWidth > 0
            ? BorderSide(
                color: resolved.borderColor ?? const Color(0x1F000000),
                width: borderWidth,
              )
            : BorderSide.none,
      ),
      child: inner,
    );

    if (isLoading) {
      return Semantics(
        container: true,
        label: semanticsLabel ?? 'Loading',
        child: ExcludeSemantics(child: card),
      );
    }

    return Semantics(
      container: true,
      button: onTap != null,
      onTap: onTap,
      label: semanticsLabel ?? '$label: $value${unit ?? ''}',
      child: ExcludeSemantics(child: card),
    );
  }

  Widget _buildSkeleton(StatCardThemeData resolved, double spacing) {
    return StatCardSkeleton(
      baseColor: resolved.skeletonBaseColor ?? const Color(0x1F000000),
      spacing: spacing,
      layout: layout,
      showIcon: icon != null && layout != StatCardLayout.noIcon,
      labelLines: labelMaxLines.clamp(1, 3),
      iconSize: resolved.iconSize ?? 24,
    );
  }

  Widget _buildContent(
    BuildContext context,
    StatCardThemeData resolved,
    double spacing,
  ) {
    final valueStyle =
        resolved.valueStyle ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
    final labelStyle = resolved.labelStyle ?? const TextStyle(fontSize: 12);
    final unitStyle = resolved.unitStyle ?? const TextStyle(fontSize: 14);

    final textColumn = SafeColumn(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (value.isNotEmpty)
          AdaptiveText(
            text: value,
            style: valueStyle,
            overflow: overflow,
            maxLines: valueMaxLines,
            minFontScale: minFontScale,
            suffix: unit,
            suffixStyle: unitStyle,
          ),
        if (label.isNotEmpty) ...<Widget>[
          if (value.isNotEmpty) SizedBox(height: spacing / 2),
          AdaptiveText(
            text: label,
            style: labelStyle,
            overflow: overflow,
            maxLines: labelMaxLines,
            minFontScale: minFontScale,
          ),
        ],
        if (trend != null) ...<Widget>[
          SizedBox(height: spacing),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: StatTrendBadge(trend: trend!, theme: resolved),
          ),
        ],
      ],
    );

    final iconWidget = icon;
    if (iconWidget == null || layout == StatCardLayout.noIcon) {
      return textColumn;
    }

    final themedIcon = IconTheme.merge(
      data: IconThemeData(
        color: resolved.iconColor,
        size: resolved.iconSize ?? 24,
      ),
      child: iconWidget,
    );

    switch (layout) {
      case StatCardLayout.noIcon:
        return textColumn;
      case StatCardLayout.iconAbove:
        return SafeColumn(
          children: <Widget>[
            themedIcon,
            SizedBox(height: spacing),
            textColumn,
          ],
        );
      case StatCardLayout.iconLeading:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            themedIcon,
            SizedBox(width: spacing),
            Expanded(child: textColumn),
          ],
        );
      case StatCardLayout.iconTrailing:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: textColumn),
            SizedBox(width: spacing),
            themedIcon,
          ],
        );
    }
  }
}
