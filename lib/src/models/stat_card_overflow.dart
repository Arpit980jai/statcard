/// Strategies that describe how a [StatCard] should degrade its text when the
/// available space is smaller than the text needs.
///
/// Every strategy is guaranteed to produce a laid out widget that fits its
/// constraints; none of them can throw a `RenderFlex`/`RenderParagraph`
/// overflow error.
///
/// ```dart
/// const StatCard(
///   value: '1,248',
///   label: 'Total deliveries completed this month',
///   overflow: StatCardOverflow.shrinkThenWrap,
/// );
/// ```
enum StatCardOverflow {
  /// Lets the text wrap up to the configured maximum number of lines and then
  /// truncates the remainder with an ellipsis.
  wrap,

  /// Keeps the text on a single line and truncates it with an ellipsis.
  ellipsis,

  /// Keeps the text on a single line with an ellipsis and reveals the full
  /// string in a [Tooltip] on hover or long press.
  ///
  /// The tooltip is only attached when the text was actually truncated.
  tooltip,

  /// Scales the font down towards `minFontScale` so that the text fits on a
  /// single line.
  shrink,

  /// Scales the font down towards `minFontScale` to fit on one line, then
  /// allows wrapping, and finally falls back to an ellipsis.
  ///
  /// This is the default because it preserves the most information while
  /// staying visually stable.
  shrinkThenWrap,

  /// Scales the font down towards `minFontScale`, then truncates with an
  /// ellipsis and exposes the full string through a [Tooltip].
  shrinkThenTooltip,

  /// Keeps the text at its natural size on a single line inside a horizontally
  /// scrollable viewport, so nothing is ever hidden.
  scroll,
}
