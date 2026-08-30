import 'package:flutter/material.dart';

import 'models/stat_card_layout.dart';
import 'models/stat_card_overflow.dart';
import 'models/stat_card_trend.dart';
import 'models/stat_card_value_format.dart';
import 'stat_card_theme.dart';
import 'widgets/adaptive_text.dart';
import 'widgets/animated_stat_value.dart';
import 'widgets/safe_column.dart';
import 'widgets/stat_card_skeleton.dart';
import 'widgets/stat_sparkline.dart';
import 'widgets/stat_trend_badge.dart';
import 'widgets/sync_registry.dart';

/// A dashboard statistic card that never overflows.
///
/// A stat card shows one big [value], a descriptive [label], and optionally an
/// [icon], a [unit] suffix, a [trend] badge and a [sparkline]. Both texts are
/// laid out by an internal measurement engine that respects the ambient text
/// scaler, so long labels, translated strings, big numbers and accessibility
/// text scaling all degrade according to [overflow] instead of throwing a
/// layout overflow.
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
///  * [StatCard.number], which formats a `num` and degrades it semantically
///    before it shrinks anything.
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
    this.sparkline,
    this.overflow = StatCardOverflow.shrinkThenWrap,
    this.layout = StatCardLayout.iconLeading,
    this.labelMaxLines = 2,
    this.valueMaxLines = 1,
    this.minFontScale = 0.7,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.error,
    this.emptyPlaceholder = '—',
    this.isLoading = false,
    this.theme,
    this.semanticsLabel,
    this.padding,
    super.key,
  }) : _dense = false,
       numericValue = null,
       format = StatCardValueFormat.auto,
       valueFormatter = null,
       animateValue = false;

  /// Creates a stat card from a number, formatting it as it degrades.
  ///
  /// A number has something a string does not: shorter renderings of itself.
  /// Rather than shrinking `1,250,000` until it fits, this constructor walks a
  /// ladder — `1,250,000`, then `1.25M`, then `1.2M` — and only starts
  /// shrinking the font once the shortest rendering still does not fit. The
  /// [overflow] chain then takes over exactly as it does for a string value.
  ///
  /// ```dart
  /// StatCard.number(
  ///   1250000,
  ///   label: 'Deliveries this month',
  ///   trend: const StatTrend.up('+12.4%'),
  ///   animateValue: true,
  /// );
  /// ```
  ///
  /// The built-in formatter is en-style (`1,250,000`, `1.25M`) and is not
  /// localised; supply [valueFormatter] to use `intl` or anything else. The
  /// accessibility label always reads the full grouped number, whatever is
  /// actually painted.
  ///
  /// Unlike the other constructors this one is not `const`, because it formats
  /// its argument.
  StatCard.number(
    num value, {
    required this.label,
    this.format = StatCardValueFormat.auto,
    this.valueFormatter,
    this.animateValue = false,
    this.icon,
    this.unit,
    this.trend,
    this.sparkline,
    this.overflow = StatCardOverflow.shrinkThenWrap,
    this.layout = StatCardLayout.iconLeading,
    this.labelMaxLines = 2,
    this.valueMaxLines = 1,
    this.minFontScale = 0.7,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.error,
    this.emptyPlaceholder = '—',
    this.isLoading = false,
    this.theme,
    this.semanticsLabel,
    this.padding,
    super.key,
  }) : numericValue = value,
       value = value.isFinite ? StatCardNumberFormat.grouped(value) : '',
       _dense = false;

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
    this.sparkline,
    this.overflow = StatCardOverflow.ellipsis,
    this.layout = StatCardLayout.iconLeading,
    this.valueMaxLines = 1,
    this.minFontScale = 0.7,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.error,
    this.emptyPlaceholder = '—',
    this.isLoading = false,
    this.theme,
    this.semanticsLabel,
    this.padding,
    super.key,
  }) : labelMaxLines = 1,
       _dense = true,
       numericValue = null,
       format = StatCardValueFormat.auto,
       valueFormatter = null,
       animateValue = false;

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
       sparkline = null,
       overflow = StatCardOverflow.shrinkThenWrap,
       valueMaxLines = 1,
       minFontScale = 0.7,
       onTap = null,
       onLongPress = null,
       selected = false,
       error = null,
       emptyPlaceholder = '—',
       isLoading = true,
       semanticsLabel = null,
       numericValue = null,
       format = StatCardValueFormat.auto,
       valueFormatter = null,
       animateValue = false,
       _dense = false;

  /// The narrowest card that still draws a [sparkline].
  ///
  /// Below this content width the line is dropped entirely rather than
  /// squeezed into something unreadable that steals room from the label.
  ///
  /// ```dart
  /// if (cardWidth < StatCard.sparklineMinWidth) {
  ///   // the sparkline will not be drawn
  /// }
  /// ```
  static const double sparklineMinWidth = 96;

  /// The height reserved for a [sparkline], in logical pixels.
  ///
  /// It does not scale with the text scaler — it is a picture, not text — but
  /// it is squeezed like every other child when the card's height is bounded.
  ///
  /// ```dart
  /// const double reserved = StatCard.sparklineHeight; // 20
  /// ```
  static const double sparklineHeight = 20;

  /// How long [animateValue] takes to count from the old value to the new one.
  ///
  /// ```dart
  /// await tester.pump(StatCard.valueAnimationDuration);
  /// ```
  static const Duration valueAnimationDuration = Duration(milliseconds: 400);

  /// The easing used while [animateValue] counts.
  ///
  /// ```dart
  /// final Curve curve = StatCard.valueAnimationCurve; // Curves.easeOutCubic
  /// ```
  static const Curve valueAnimationCurve = Curves.easeOutCubic;

  /// The headline number, already formatted for display, such as `'1,248'`.
  ///
  /// For [StatCard.number] this is the full grouped rendering of the number,
  /// whatever the card ends up painting.
  final String value;

  /// The number behind [value], or null for a string-valued card.
  final num? numericValue;

  /// How [numericValue] is rendered as it degrades.
  ///
  /// Ignored unless the card was built with [StatCard.number].
  final StatCardValueFormat format;

  /// Replaces the built-in formatter for [StatCard.number].
  ///
  /// It is called with the number and the width actually available to the
  /// value, so it can decide how much to abbreviate. This is the intended
  /// place for `intl`, which the package itself will not depend on:
  ///
  /// ```dart
  /// StatCard.number(
  ///   1250000,
  ///   label: 'Deliveries',
  ///   valueFormatter: (num value, double availableWidth) =>
  ///       NumberFormat.compact(locale: 'de').format(value),
  /// );
  /// ```
  ///
  /// A formatter returns one string rather than a ladder, so the card falls
  /// straight through to the [overflow] chain when the result does not fit.
  final String Function(num value, double availableWidth)? valueFormatter;

  /// Whether a change to [StatCard.number]'s value counts up to the new one.
  ///
  /// The count is suppressed when `MediaQuery.disableAnimations` is set. Only
  /// the two endpoints are ever measured, so an animation in flight cannot
  /// churn the shared measurement cache.
  ///
  /// ```dart
  /// StatCard.number(deliveries, label: 'Deliveries', animateValue: true);
  /// ```
  final bool animateValue;

  /// The descriptive text under the value, such as `'Deliveries this month'`.
  final String label;

  /// An optional leading widget, typically an [Icon] or a small image.
  final Widget? icon;

  /// An optional short suffix rendered next to [value], such as `'kg'`.
  final String? unit;

  /// An optional delta badge rendered under the label.
  final StatTrend? trend;

  /// An optional series drawn as a trend line under the label.
  ///
  /// The line is dropped, without any layout jump, when it has fewer than two
  /// points or when the card is narrower than [sparklineMinWidth]. Its colour
  /// and thickness come from [StatCardThemeData.sparklineColor] and
  /// [StatCardThemeData.sparklineStrokeWidth].
  ///
  /// ```dart
  /// StatCard(
  ///   value: '1,248',
  ///   label: 'Deliveries',
  ///   sparkline: const <double>[3, 5, 4, 9, 8, 12, 11, 15],
  /// );
  /// ```
  final List<double>? sparkline;

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
  /// When both this and [onLongPress] are null, the card is not wrapped in an
  /// [InkWell] at all.
  final VoidCallback? onTap;

  /// Called when the card is long pressed.
  ///
  /// Useful for a context menu or a "pin this metric" gesture. Note that
  /// [StatCardOverflow.tooltip] also uses a long press to reveal truncated
  /// text; when both are in play the tooltip wins for a press that lands on
  /// the truncated text itself, and this callback wins everywhere else on the
  /// card.
  ///
  /// ```dart
  /// StatCard(
  ///   value: '1,248',
  ///   label: 'Deliveries',
  ///   onLongPress: () => showMetricMenu(context),
  /// );
  /// ```
  final VoidCallback? onLongPress;

  /// Whether the card is drawn as selected.
  ///
  /// A selected card takes the resolved [StatCardThemeData.iconColor] as its
  /// border colour and doubles its border width, and is announced as selected
  /// by a screen reader.
  ///
  /// ```dart
  /// StatCard(
  ///   value: '1,248',
  ///   label: 'Deliveries',
  ///   selected: metric == Metric.deliveries,
  ///   onTap: () => select(Metric.deliveries),
  /// );
  /// ```
  final bool selected;

  /// An error to display instead of the value.
  ///
  /// When this is not null the card renders an error glyph where the value
  /// would be, keeps the label, and exposes `error.toString()` both as a
  /// tooltip and to screen readers. It takes precedence over [isLoading].
  ///
  /// ```dart
  /// StatCard(
  ///   value: '',
  ///   label: 'Deliveries',
  ///   error: snapshot.error,
  /// );
  /// ```
  final Object? error;

  /// Rendered in place of an empty [value]. Defaults to an em dash.
  ///
  /// This is what a metric that legitimately has no reading looks like, as
  /// opposed to one that is still loading ([isLoading]) or that failed
  /// ([error]).
  ///
  /// ```dart
  /// StatCard(value: '', label: 'Deliveries', emptyPlaceholder: 'n/a');
  /// ```
  final String emptyPlaceholder;

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

  /// The string that stands in for a value the card does not have.
  String get _displayValue => value.isEmpty ? emptyPlaceholder : value;

  @override
  Widget build(BuildContext context) {
    final resolved = StatCardThemeData.resolve(context, theme);
    final radius = BorderRadius.circular(resolved.borderRadius ?? 16);
    final spacing = (resolved.spacing ?? 8) * (_dense ? 0.75 : 1.0);
    final baseBorderWidth = resolved.borderWidth ?? 1;
    final borderWidth = selected
        ? (baseBorderWidth <= 0 ? 2.0 : baseBorderWidth * 2)
        : baseBorderWidth;
    final borderColor = selected
        ? (resolved.iconColor ?? Theme.of(context).colorScheme.primary)
        : (resolved.borderColor ?? const Color(0x1F000000));
    final effectivePadding =
        padding ??
        (_dense
            ? const EdgeInsetsDirectional.all(10)
            : (resolved.padding ?? const EdgeInsets.all(16)));

    final bool showSkeleton = error == null && isLoading;
    final Widget content;
    if (error != null) {
      content = _buildError(context, resolved, spacing);
    } else if (isLoading) {
      content = _buildSkeleton(resolved, spacing);
    } else {
      content = _buildContent(context, resolved, spacing);
    }

    Widget inner = Padding(padding: effectivePadding, child: content);
    if (onTap != null || onLongPress != null) {
      inner = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: inner,
      );
    }

    final card = Material(
      color: resolved.backgroundColor,
      elevation: resolved.elevation ?? 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: borderWidth > 0
            ? BorderSide(color: borderColor, width: borderWidth)
            : BorderSide.none,
      ),
      child: inner,
    );

    if (showSkeleton) {
      return Semantics(
        container: true,
        label: semanticsLabel ?? 'Loading',
        child: ExcludeSemantics(child: card),
      );
    }

    return Semantics(
      container: true,
      button: onTap != null,
      selected: selected ? true : null,
      onTap: onTap,
      onLongPress: onLongPress,
      label: semanticsLabel ?? _semanticsLabel,
      child: ExcludeSemantics(child: card),
    );
  }

  /// What a screen reader reads for this card.
  String get _semanticsLabel {
    if (error != null) {
      return '$label: ${error!}';
    }
    return '$label: $_displayValue${unit ?? ''}';
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

  /// The failed state: an error glyph where the value goes, label intact.
  Widget _buildError(
    BuildContext context,
    StatCardThemeData resolved,
    double spacing,
  ) {
    final Color color =
        resolved.downColor ?? Theme.of(context).colorScheme.error;
    final labelStyle = resolved.labelStyle ?? const TextStyle(fontSize: 12);
    final double glyphSize =
        (resolved.valueStyle?.fontSize ?? 24) * (_dense ? 0.8 : 1);

    return SafeColumn(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Tooltip(
          message: error!.toString(),
          child: Icon(
            Icons.error_outline_rounded,
            color: color,
            size: glyphSize,
          ),
        ),
        if (label.isNotEmpty) ...<Widget>[
          SizedBox(height: spacing / 2),
          AdaptiveText(
            text: label,
            style: labelStyle.copyWith(color: color),
            overflow: overflow,
            maxLines: labelMaxLines,
            minFontScale: minFontScale,
            syncRole: SyncRole.label,
          ),
        ],
      ],
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
        if (_displayValue.isNotEmpty)
          _buildValue(valueStyle: valueStyle, unitStyle: unitStyle),
        if (label.isNotEmpty) ...<Widget>[
          if (_displayValue.isNotEmpty) SizedBox(height: spacing / 2),
          AdaptiveText(
            text: label,
            style: labelStyle,
            overflow: overflow,
            maxLines: labelMaxLines,
            minFontScale: minFontScale,
            syncRole: SyncRole.label,
          ),
        ],
        ..._buildSparkline(resolved, spacing),
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

  /// The headline, which is a plain string, a formatted number, or a number
  /// counting towards its new reading.
  Widget _buildValue({
    required TextStyle valueStyle,
    required TextStyle unitStyle,
  }) {
    final num? number = numericValue;
    if (number == null || !number.isFinite) {
      return AdaptiveText(
        text: _displayValue,
        style: valueStyle,
        overflow: overflow,
        maxLines: valueMaxLines,
        minFontScale: minFontScale,
        suffix: unit,
        suffixStyle: unitStyle,
        syncRole: SyncRole.value,
      );
    }

    if (!animateValue) {
      return AdaptiveText(
        text: value,
        style: valueStyle,
        overflow: overflow,
        maxLines: valueMaxLines,
        minFontScale: minFontScale,
        suffix: unit,
        suffixStyle: unitStyle,
        syncRole: SyncRole.value,
        candidates: (double maxWidth) => _ladderFor(number, maxWidth),
      );
    }

    return AnimatedStatValue(
      value: number,
      duration: valueAnimationDuration,
      curve: valueAnimationCurve,
      builder: (BuildContext context, num from, num to, num current) {
        // Measure the wider endpoint and paint the current frame against that
        // decision, so the only cache keys an animation creates are the two it
        // would have created without animating at all.
        final num measured = _wider(from, to);
        return AdaptiveText(
          text: value,
          style: valueStyle,
          overflow: overflow,
          maxLines: valueMaxLines,
          minFontScale: minFontScale,
          suffix: unit,
          suffixStyle: unitStyle,
          syncRole: SyncRole.value,
          candidates: (double maxWidth) => _ladderFor(measured, maxWidth),
          displayCandidates: (double maxWidth) => _ladderFor(current, maxWidth),
        );
      },
    );
  }

  /// The ordered renderings of [number] that the engine may choose between.
  List<String> _ladderFor(num number, double maxWidth) {
    final formatter = valueFormatter;
    if (formatter != null) {
      return <String>[formatter(number, maxWidth)];
    }
    return StatCardNumberFormat.ladder(number, format);
  }

  /// Whichever endpoint of an animation needs more room.
  static num _wider(num a, num b) {
    final int lengthA = StatCardNumberFormat.grouped(a).length;
    final int lengthB = StatCardNumberFormat.grouped(b).length;
    return lengthB > lengthA ? b : a;
  }

  /// The sparkline, or nothing at all when it would not be legible.
  List<Widget> _buildSparkline(StatCardThemeData resolved, double spacing) {
    final List<double>? points = sparkline;
    if (points == null || points.length < 2) {
      return const <Widget>[];
    }
    return <Widget>[
      SizedBox(height: spacing / 2),
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Below the threshold the line is dropped rather than drawn as an
          // unreadable smudge that steals room from the label.
          if (constraints.maxWidth.isFinite &&
              constraints.maxWidth < sparklineMinWidth) {
            return const SizedBox.shrink();
          }
          return StatSparkline(
            points: points,
            color:
                resolved.sparklineColor ??
                resolved.iconColor ??
                const Color(0xFF3B6EF3),
            strokeWidth: resolved.sparklineStrokeWidth ?? 1.5,
            height: sparklineHeight * (_dense ? 0.8 : 1),
          );
        },
      ),
    ];
  }
}
