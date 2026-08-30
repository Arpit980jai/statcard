import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../fit_cache.dart';
import '../models/stat_card_overflow.dart';
import 'sync_registry.dart';

/// The measured outcome of fitting a string into a box.
@immutable
class _FitResult {
  const _FitResult({
    required this.index,
    required this.fontSize,
    required this.maxLines,
    required this.truncated,
  });

  /// The position in the candidate ladder that was selected.
  final int index;

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
    required this.texts,
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
    required this.cap,
  });

  final List<String> texts;
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

  /// The size dictated by an enclosing sync scope, or null when unsynced.
  final double? cap;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _FitKey &&
        listEquals(other.texts, texts) &&
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
        other.suffixStyle == suffixStyle &&
        other.cap == cap;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    Object.hashAll(texts),
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
    cap,
  ]);
}

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
/// Before any font shrinking happens, the widget walks the ladder returned by
/// [candidates]: the first candidate that fits at the full font size wins. That
/// is how a numeric card degrades `1,250,000` into `1.25M` rather than
/// shrinking the digits into illegibility. With a single candidate the
/// behaviour is exactly the shrink/wrap/ellipsis chain of [overflow].
///
/// This class is internal to the package and is not exported.
class AdaptiveText extends StatefulWidget {
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
    this.candidates,
    this.displayCandidates,
    this.syncRole,
    this.tooltipTriggerMode,
    super.key,
  });

  /// The canonical string: the tooltip message, and the only candidate when
  /// [candidates] is null.
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

  /// The ordered degradation ladder, most informative first.
  ///
  /// It receives the width actually available, so a caller-supplied formatter
  /// can take the box into account. Null or empty means `<String>[text]`.
  final List<String> Function(double maxWidth)? candidates;

  /// Strings painted in place of the chosen candidate, index for index.
  ///
  /// Only the ladder from [candidates] is measured and cached; this is what an
  /// animating number substitutes on every frame, so that a running animation
  /// never churns the measurement cache.
  final List<String> Function(double maxWidth)? displayCandidates;

  /// Which sync group this text belongs to, or null to never participate.
  final SyncRole? syncRole;

  /// Overrides how a truncation tooltip is triggered.
  final TooltipTriggerMode? tooltipTriggerMode;

  @override
  State<AdaptiveText> createState() => _AdaptiveTextState();
}

class _AdaptiveTextState extends State<AdaptiveText> {
  /// Identity of this text inside a sync scope. A plain object is enough: it
  /// lives exactly as long as this element does.
  final Object _token = Object();

  StatCardSyncRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final StatCardSyncRegistry? registry = widget.syncRole == null
        ? null
        : StatCardSyncMarker.maybeOf(context);
    if (!identical(registry, _registry)) {
      _registry?.remove(_token);
      _registry = registry;
    }
  }

  @override
  void dispose() {
    _registry?.remove(_token);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty && widget.candidates == null) {
      return const SizedBox.shrink();
    }

    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final inherited = DefaultTextStyle.of(context).style;
    final baseStyle = inherited.merge(widget.style);
    final baseSuffixStyle = widget.suffixStyle == null
        ? null
        : inherited.merge(widget.suffixStyle);

    if (widget.overflow == StatCardOverflow.scroll) {
      // Nothing is ever hidden in scroll mode, so no measurement is needed.
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Text.rich(
          _span(
            _display(_ladder(double.infinity), 0, double.infinity),
            baseStyle,
            baseSuffixStyle,
            baseStyle.fontSize ?? 14.0,
          ),
          maxLines: 1,
          softWrap: false,
          textAlign: widget.textAlign,
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
            _span(
              _display(_ladder(maxWidth), 0, maxWidth),
              baseStyle,
              baseSuffixStyle,
              baseStyle.fontSize ?? 14.0,
            ),
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: widget.textAlign,
          );
        }

        final List<String> ladder = _ladder(maxWidth);
        final _FitResult natural = _resolve(
          texts: ladder,
          baseStyle: baseStyle,
          baseSuffixStyle: baseSuffixStyle,
          maxWidth: maxWidth,
          maxHeight: constraints.maxHeight,
          scaler: scaler,
          direction: direction,
          cap: null,
        );

        // Report the size this text would have picked on its own, never the
        // size the scope told it to paint. Reports are therefore independent
        // of the broadcast, which is what makes the scope converge.
        var result = natural;
        final StatCardSyncRegistry? registry = _registry;
        final SyncRole? role = widget.syncRole;
        if (registry != null && role != null) {
          registry.report(role, _token, natural.fontSize);
          final double? agreed = registry.sizeFor(role);
          if (agreed != null && agreed < natural.fontSize) {
            result = _resolve(
              texts: ladder,
              baseStyle: baseStyle,
              baseSuffixStyle: baseSuffixStyle,
              maxWidth: maxWidth,
              maxHeight: constraints.maxHeight,
              scaler: scaler,
              direction: direction,
              cap: agreed,
            );
          }
        }

        Widget child = Text.rich(
          _span(
            _display(ladder, result.index, maxWidth),
            baseStyle,
            baseSuffixStyle,
            result.fontSize,
          ),
          maxLines: result.maxLines,
          overflow: TextOverflow.ellipsis,
          softWrap: result.maxLines > 1,
          textAlign: widget.textAlign,
        );

        final wantsTooltip =
            widget.overflow == StatCardOverflow.tooltip ||
            widget.overflow == StatCardOverflow.shrinkThenTooltip;
        if (wantsTooltip && result.truncated) {
          // Never attach a redundant tooltip to text that is fully visible.
          final String suffix = widget.suffix ?? '';
          child = Tooltip(
            message: suffix.isEmpty ? widget.text : '${widget.text} $suffix',
            triggerMode: widget.tooltipTriggerMode,
            child: child,
          );
        }
        return child;
      },
    );
  }

  /// The measurement ladder for the given width, never empty.
  List<String> _ladder(double maxWidth) {
    final List<String>? supplied = widget.candidates?.call(maxWidth);
    if (supplied == null || supplied.isEmpty) {
      return <String>[widget.text];
    }
    return supplied;
  }

  /// The string actually painted for the chosen ladder [index].
  String _display(List<String> ladder, int index, double maxWidth) {
    final List<String>? shown = widget.displayCandidates?.call(maxWidth);
    if (shown != null && index < shown.length) {
      return shown[index];
    }
    return index < ladder.length ? ladder[index] : widget.text;
  }

  /// Builds the paragraph for a candidate font [size].
  ///
  /// The value and the unit share one paragraph so that they are measured
  /// together and are baseline aligned without a [Row].
  InlineSpan _span(
    String text,
    TextStyle baseStyle,
    TextStyle? baseSuffixStyle,
    double size,
  ) {
    final base = baseStyle.fontSize ?? 14.0;
    final ratio = base == 0 ? 1.0 : size / base;
    final suffixText = widget.suffix;
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
    required List<String> texts,
    required TextStyle baseStyle,
    required TextStyle? baseSuffixStyle,
    required double maxWidth,
    required double maxHeight,
    required TextScaler scaler,
    required TextDirection direction,
    required double? cap,
  }) {
    final key = _FitKey(
      texts: texts,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      scaler: scaler,
      style: baseStyle,
      maxLines: widget.maxLines,
      minFontScale: widget.minFontScale,
      overflow: widget.overflow,
      direction: direction,
      textAlign: widget.textAlign,
      suffix: widget.suffix,
      suffixStyle: baseSuffixStyle,
      cap: cap,
    );
    final Object? cached = fitCache[key];
    if (cached is _FitResult) {
      return cached;
    }

    final result = _measure(
      texts: texts,
      baseStyle: baseStyle,
      baseSuffixStyle: baseSuffixStyle,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      scaler: scaler,
      direction: direction,
      cap: cap,
    );

    fitCache[key] = result;
    return result;
  }

  _FitResult _measure({
    required List<String> texts,
    required TextStyle baseStyle,
    required TextStyle? baseSuffixStyle,
    required double maxWidth,
    required double maxHeight,
    required TextScaler scaler,
    required TextDirection direction,
    required double? cap,
  }) {
    final base = baseStyle.fontSize ?? 14.0;
    final scale = widget.minFontScale.clamp(0.1, 1.0);
    final floor = base * scale;

    // A line that is taller than the box can never be shown, so cap the line
    // budget by the available height before doing anything else.
    final lineBudget = _lineBudget(
      baseStyle: baseStyle,
      base: base,
      maxHeight: maxHeight,
      scaler: scaler,
    );

    bool fitsAt(String text, double size, int lines) => _fits(
      text: text,
      baseStyle: baseStyle,
      baseSuffixStyle: baseSuffixStyle,
      size: size,
      lines: lines,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      scaler: scaler,
      direction: direction,
    );

    // Semantic degradation comes first: a shorter rendering of the same number
    // at the full font size always beats the same number shrunk.
    final int lastIndex = texts.length - 1;
    final int ladderLines = switch (widget.overflow) {
      StatCardOverflow.wrap || StatCardOverflow.shrinkThenWrap => lineBudget,
      _ => 1,
    };
    final double ladderSize = cap ?? base;
    for (var i = 0; i < lastIndex; i++) {
      if (fitsAt(texts[i], ladderSize, ladderLines)) {
        return _FitResult(
          index: i,
          fontSize: ladderSize,
          maxLines: ladderLines,
          truncated: false,
        );
      }
    }

    final String text = texts[lastIndex];
    bool fits(double size, int lines) => fitsAt(text, size, lines);

    // Inside a sync scope the size is dictated from outside; only the line
    // count and the truncation flag still have to be worked out.
    if (cap != null) {
      final int lines = ladderLines == 1 || fits(cap, 1) ? 1 : lineBudget;
      return _FitResult(
        index: lastIndex,
        fontSize: cap,
        maxLines: lines,
        truncated: !fits(cap, lines),
      );
    }

    switch (widget.overflow) {
      case StatCardOverflow.scroll:
      case StatCardOverflow.wrap:
        return _FitResult(
          index: lastIndex,
          fontSize: base,
          maxLines: lineBudget,
          truncated: !fits(base, lineBudget),
        );

      case StatCardOverflow.ellipsis:
      case StatCardOverflow.tooltip:
        return _FitResult(
          index: lastIndex,
          fontSize: base,
          maxLines: 1,
          truncated: !fits(base, 1),
        );

      case StatCardOverflow.shrink:
      case StatCardOverflow.shrinkThenTooltip:
        final size = _search(base: base, floor: floor, lines: 1, fits: fits);
        return _FitResult(
          index: lastIndex,
          fontSize: size,
          maxLines: 1,
          truncated: !fits(size, 1),
        );

      case StatCardOverflow.shrinkThenWrap:
        // 1. The happy path: it already fits on one line at full size.
        if (fits(base, 1)) {
          return _FitResult(
            index: lastIndex,
            fontSize: base,
            maxLines: 1,
            truncated: false,
          );
        }
        // 2. Shrink, as long as one line is still achievable.
        if (lineBudget == 1 || fits(floor, 1)) {
          final size = _search(base: base, floor: floor, lines: 1, fits: fits);
          return _FitResult(
            index: lastIndex,
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
          index: lastIndex,
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
      return widget.maxLines;
    }
    final lineHeight = scaler.scale(base) * (baseStyle.height ?? 1.2);
    if (lineHeight <= 0) {
      return widget.maxLines;
    }
    final fitting = (maxHeight / lineHeight).floor();
    return fitting.clamp(1, widget.maxLines);
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
    required String text,
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
      text: _span(text, baseStyle, baseSuffixStyle, size),
      textDirection: direction,
      textAlign: widget.textAlign ?? TextAlign.start,
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
