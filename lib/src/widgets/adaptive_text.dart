import 'package:flutter/material.dart';

import '../models/stat_card_overflow.dart';

/// The measured outcome of fitting a string into a box.
@immutable
class _FitResult {
  const _FitResult({
    required this.fontSize,
    required this.maxLines,
    required this.truncated,
  });

  /// The font size that should actually be painted.
  final double fontSize;

  /// The number of lines the text may occupy.
  final int maxLines;

  /// Whether the string still does not fit and will be clipped.
  final bool truncated;
}

/// Cache key covering every input that can change a measurement outcome.
@immutable
class _FitKey {
  const _FitKey({
    required this.text,
    required this.maxWidth,
    required this.maxHeight,
    required this.scaler,
    required this.style,
    required this.maxLines,
    required this.minFontScale,
    required this.overflow,
    required this.direction,
    required this.textAlign,
    required this.suffix,
    required this.suffixStyle,
  });

  final String text;
  final double maxWidth;
  final double maxHeight;
  final TextScaler scaler;
  final TextStyle style;
  final int maxLines;
  final double minFontScale;
  final StatCardOverflow overflow;
  final TextDirection direction;
  final TextAlign? textAlign;
  final String? suffix;
  final TextStyle? suffixStyle;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _FitKey &&
        other.text == text &&
        other.maxWidth == maxWidth &&
        other.maxHeight == maxHeight &&
        other.scaler == scaler &&
        other.style == style &&
        other.maxLines == maxLines &&
        other.minFontScale == minFontScale &&
        other.overflow == overflow &&
        other.direction == direction &&
        other.textAlign == textAlign &&
        other.suffix == suffix &&
        other.suffixStyle == suffixStyle;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    text,
    maxWidth,
    maxHeight,
    scaler,
    style,
    maxLines,
    minFontScale,
    overflow,
    direction,
    textAlign,
    suffix,
    suffixStyle,
  ]);
}

/// Process wide measurement cache. A single layout pass repeats the same query
/// many times, and `TextPainter.layout` is the most expensive thing this
/// package does.
final Map<_FitKey, _FitResult> _fitCache = <_FitKey, _FitResult>{};

/// Upper bound on cached entries, so a long lived app with changing data can
/// never grow the cache without limit.
const int _maxCacheEntries = 512;

/// A text widget that always fits the box it is given.
///
/// This is the measurement engine behind every stat card. It measures the
/// string with a [TextPainter] using the ambient [Directionality] and,
/// crucially, the ambient [MediaQuery] text scaler, then applies the requested
/// [StatCardOverflow] strategy. Shrinking strategies binary search the font
/// size between `style.fontSize * minFontScale` and `style.fontSize` rather
/// than stepping one pixel at a time.
///
/// The style used for measurement is the ambient [DefaultTextStyle] merged with
/// [style], which is exactly the style that ends up being painted. Measuring
/// anything else is how competing implementations end up off by a font family.
///
/// This class is internal to the package and is not exported.
class AdaptiveText extends StatelessWidget {
  /// Creates a text widget that adapts itself to its constraints.
  const AdaptiveText({
    required this.text,
    required this.style,
    required this.overflow,
    required this.maxLines,
    required this.minFontScale,
    this.textAlign,
    this.suffix,
    this.suffixStyle,
    super.key,
  });

  /// The string to render.
  final String text;

  /// The base style. Its `fontSize` is the largest size that will be used.
  final TextStyle style;

  /// How the text should degrade when it does not fit.
  final StatCardOverflow overflow;

  /// The maximum number of lines the text may wrap onto.
  final int maxLines;

  /// The lowest fraction of `style.fontSize` a shrink strategy may use.
  final double minFontScale;

  /// Horizontal alignment of the rendered text.
  final TextAlign? textAlign;

  /// An optional smaller trailing string, such as a unit.
  ///
  /// It shares a single paragraph with [text], so the two are measured together
  /// and are baseline aligned by construction rather than by a [Row].
  final String? suffix;

  /// Style of [suffix]. Its font size is scaled by the same factor as [text].
  final TextStyle? suffixStyle;

  /// Clears the internal measurement cache.
  ///
  /// Only useful in tests that assert on measurement behaviour.
  @visibleForTesting
  static void debugClearCache() => _fitCache.clear();

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final inherited = DefaultTextStyle.of(context).style;
    final baseStyle = inherited.merge(style);
    final baseSuffixStyle = suffixStyle == null
        ? null
        : inherited.merge(suffixStyle);

    if (overflow == StatCardOverflow.scroll) {
      // Nothing is ever hidden in scroll mode, so no measurement is needed.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Text.rich(
          _span(baseStyle, baseSuffixStyle, baseStyle.fontSize ?? 14.0),
          maxLines: 1,
          softWrap: false,
          textAlign: textAlign,
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          // Unbounded (or degenerate) width: measurement is meaningless, so
          // render plainly and let the parent decide.
          return Text.rich(
            _span(baseStyle, baseSuffixStyle, baseStyle.fontSize ?? 14.0),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          );
        }

        final result = _resolve(
          baseStyle: baseStyle,
          baseSuffixStyle: baseSuffixStyle,
          maxWidth: maxWidth,
          maxHeight: constraints.maxHeight,
          scaler: scaler,
          direction: direction,
        );

        Widget child = Text.rich(
          _span(baseStyle, baseSuffixStyle, result.fontSize),
          maxLines: result.maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: result.maxLines > 1,
          textAlign: textAlign,
        );

        final wantsTooltip =
            overflow == StatCardOverflow.tooltip ||
            overflow == StatCardOverflow.shrinkThenTooltip;
        if (wantsTooltip && result.truncated) {
          // Never attach a redundant tooltip to text that is fully visible.
          child = Tooltip(
            message: suffix == null || suffix!.isEmpty ? text : '$text $suffix',
            child: child,
          );
        }
        return child;
      },
    );
  }

  /// Builds the paragraph for a candidate font [size].
  ///
  /// The value and the unit share one paragraph so that they are measured
  /// together and are baseline aligned without a [Row].
  InlineSpan _span(
    TextStyle baseStyle,
    TextStyle? baseSuffixStyle,
    double size,
  ) {
    final base = baseStyle.fontSize ?? 14.0;
    final ratio = base == 0 ? 1.0 : size / base;
    final suffixText = suffix;
    return TextSpan(
      text: text,
      style: baseStyle.copyWith(fontSize: size),
      children: suffixText == null || suffixText.isEmpty
          ? null
          : <InlineSpan>[
              TextSpan(
                text: ' $suffixText',
                style: (baseSuffixStyle ?? baseStyle).copyWith(
                  fontSize: (baseSuffixStyle?.fontSize ?? base * 0.6) * ratio,
                ),
              ),
            ],
    );
  }

  _FitResult _resolve({
    required TextStyle baseStyle,
    required TextStyle? baseSuffixStyle,
    required double maxWidth,
    required double maxHeight,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    final key = _FitKey(
      text: text,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      scaler: scaler,
      style: baseStyle,
      maxLines: maxLines,
      minFontScale: minFontScale,
      overflow: overflow,
      direction: direction,
      textAlign: textAlign,
      suffix: suffix,
      suffixStyle: baseSuffixStyle,
    );
    final cached = _fitCache[key];
    if (cached != null) {
      return cached;
    }

    final result = _measure(
      baseStyle: baseStyle,
      baseSuffixStyle: baseSuffixStyle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      scaler: scaler,
      direction: direction,
    );

    if (_fitCache.length >= _maxCacheEntries) {
      _fitCache.clear();
    }
    _fitCache[key] = result;
    return result;
  }

  _FitResult _measure({
    required TextStyle baseStyle,
    required TextStyle? baseSuffixStyle,
    required double maxWidth,
    required double maxHeight,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    final base = baseStyle.fontSize ?? 14.0;
    final scale = minFontScale.clamp(0.1, 1.0);
    final floor = base * scale;

    // A line that is taller than the box can never be shown, so cap the line
    // budget by the available height before doing anything else.
    final lineBudget = _lineBudget(
      baseStyle: baseStyle,
      base: base,
      maxHeight: maxHeight,
      scaler: scaler,
    );

    bool fits(double size, int lines) => _fits(
      baseStyle: baseStyle,
      baseSuffixStyle: baseSuffixStyle,
      size: size,
      lines: lines,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      scaler: scaler,
      direction: direction,
    );

    switch (overflow) {
      case StatCardOverflow.scroll:
      case StatCardOverflow.wrap:
        return _FitResult(
          fontSize: base,
          maxLines: lineBudget,
          truncated: !fits(base, lineBudget),
        );

      case StatCardOverflow.ellipsis:
      case StatCardOverflow.tooltip:
        return _FitResult(
          fontSize: base,
          maxLines: 1,
          truncated: !fits(base, 1),
        );

      case StatCardOverflow.shrink:
      case StatCardOverflow.shrinkThenTooltip:
        final size = _search(base: base, floor: floor, lines: 1, fits: fits);
        return _FitResult(
          fontSize: size,
          maxLines: 1,
          truncated: !fits(size, 1),
        );

      case StatCardOverflow.shrinkThenWrap:
        // 1. The happy path: it already fits on one line at full size.
        if (fits(base, 1)) {
          return _FitResult(fontSize: base, maxLines: 1, truncated: false);
        }
        // 2. Shrink, as long as one line is still achievable.
        if (lineBudget == 1 || fits(floor, 1)) {
          final size = _search(base: base, floor: floor, lines: 1, fits: fits);
          return _FitResult(
            fontSize: size,
            maxLines: 1,
            truncated: !fits(size, 1),
          );
        }
        // 3. Wrap, shrinking only as far as the extra lines still require.
        final size = _search(
          base: base,
          floor: floor,
          lines: lineBudget,
          fits: fits,
        );
        return _FitResult(
          fontSize: size,
          maxLines: lineBudget,
          truncated: !fits(size, lineBudget),
        );
    }
  }

  /// The number of lines that actually have room inside [maxHeight].
  int _lineBudget({
    required TextStyle baseStyle,
    required double base,
    required double maxHeight,
    required TextScaler scaler,
  }) {
    if (!maxHeight.isFinite || maxHeight <= 0) {
      return maxLines;
    }
    final lineHeight = scaler.scale(base) * (baseStyle.height ?? 1.2);
    if (lineHeight <= 0) {
      return maxLines;
    }
    final fitting = (maxHeight / lineHeight).floor();
    return fitting.clamp(1, maxLines);
  }

  /// Binary searches the largest font size in `[floor, base]` that fits.
  ///
  /// Returns [floor] when even the smallest permitted size does not fit; the
  /// caller then falls back to an ellipsis.
  double _search({
    required double base,
    required double floor,
    required int lines,
    required bool Function(double size, int lines) fits,
  }) {
    if (fits(base, lines)) {
      return base;
    }
    if (!fits(floor, lines)) {
      return floor;
    }
    var low = floor;
    var high = base;
    var best = floor;
    for (var i = 0; i < 8; i++) {
      final mid = (low + high) / 2;
      if (fits(mid, lines)) {
        best = mid;
        low = mid;
      } else {
        high = mid;
      }
    }
    return best;
  }

  bool _fits({
    required TextStyle baseStyle,
    required TextStyle? baseSuffixStyle,
    required double size,
    required int lines,
    required double maxWidth,
    required double maxHeight,
    required TextScaler scaler,
    required TextDirection direction,
  }) {
    final painter = TextPainter(
      text: _span(baseStyle, baseSuffixStyle, size),
      textDirection: direction,
      textAlign: textAlign ?? TextAlign.start,
      maxLines: lines,
      textScaler: scaler,
    )..layout(maxWidth: maxWidth);

    // `didExceedMaxLines` catches vertical overflow, but an unbreakable word
    // (a German compound, a long number) overflows horizontally without ever
    // needing a second line, so line widths must be checked as well.
    final exceededLines = painter.didExceedMaxLines;
    final tooWide = painter.computeLineMetrics().any(
      (LineMetrics m) => m.width > maxWidth + 0.5,
    );
    final tooTall = maxHeight.isFinite && painter.height > maxHeight + 0.5;
    painter.dispose();

    return !exceededLines && !tooWide && !tooTall;
  }
}
