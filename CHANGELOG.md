## 0.2.0 - 2026-08-30

Added:

- `StatCardSyncScope`: an inherited scope that makes every `StatCard` beneath it
  converge on a single font size — the smallest any card in the group needed —
  so a row of cards reads as one object instead of five independently fitted
  ones. Values synchronise with values and labels with labels. Cards report the
  size they would have picked on their own rather than the size they were told
  to paint, so the minimum is a fixed point after one extra frame and cannot
  oscillate; adding and removing cards recomputes it both ways. Without a scope
  every card behaves exactly as it did in 0.1.0.
- `StatCard.number(num value, {StatCardValueFormat format = .auto, ...})`:
  degrades the value semantically before it shrinks the font. The ladder is
  `1,250,000` → `1.25M` → `1.2M`, and only then the existing `StatCardOverflow`
  chain. The accessibility label always reads the full grouped number, whatever
  is painted.
- `StatCardNumberFormat`, a dependency-free `grouped` / `compact` formatter, and
  `StatCardValueFormat` to pick between `auto`, `grouped` and `compact`. The
  output is en-style and deliberately not localised; supply
  `valueFormatter: (num value, double availableWidth) => ...` to plug in `intl`
  or anything else. Compact digits are truncated rather than rounded, so
  `1.25M` shortens to `1.2M` instead of jumping to `1.3M`.
- `sparkline: List<double>?`: a trend line drawn under the label by a
  `CustomPainter`, with no charting dependency. It is omitted entirely when the
  series has fewer than two points or the card is narrower than
  `StatCard.sparklineMinWidth` (96 px of content). Colour and thickness come
  from the new `StatCardThemeData.sparklineColor` and
  `StatCardThemeData.sparklineStrokeWidth`.
- `animateValue: bool` on `StatCard.number`: counts from the old reading to the
  new one with a `TweenAnimationBuilder`, suppressed when
  `MediaQuery.disableAnimations` is set. Only the two endpoints are measured, so
  a count in flight adds nothing to the shared measurement cache.
- `error: Object?`, which renders an error glyph in place of the value, keeps
  the label, and exposes the message as a tooltip and to screen readers; it
  takes precedence over `isLoading`.
- `emptyPlaceholder: String = '—'`, rendered when the value is empty, so a
  metric with no reading is visibly different from one still loading.
- `onLongPress: VoidCallback?` and `selected: bool`, both reflected in the card's
  semantics; a selected card takes the theme's icon colour as its border and
  doubles its border width.
- `clearFitCache()`, `debugFitCacheLength()` and `kFitCacheMaxEntries`, for
  tests that need a cold measurement cache or want to assert it stays bounded.

Fixed:

- The text-fit cache is now a real 200-entry LRU. It was keyed on the value
  string and guarded only by a clear-everything-at-512 check, so a dashboard
  refreshing its numbers filled it up and then discarded every warm entry at
  once. Eviction is now least-recently-used, one entry at a time.
- `StatCardGrid` counts `spacing` when choosing its column count. It divided the
  available width by `minCardWidth` alone and so claimed a column the row could
  not pay for: a 600 px grid of 100 px cards was split into six 90 px columns.
  The count is now `((maxWidth + spacing) / (minCardWidth + spacing)).floor()`,
  clamped as before, and no card is ever narrower than `minCardWidth`. Grids
  near a breakpoint may drop one column relative to 0.1.0 — that is the fix.

Notes:

- `StatCardOverflow.tooltip` and `onTap` were verified not to conflict on touch
  devices: a long press opens the tooltip without firing `onTap`, and a tap
  fires `onTap` without opening the tooltip. Both directions are now covered by
  tests.
- A non-loading card with an empty `value` now renders `emptyPlaceholder`
  instead of nothing.
- The stress suite gained 88 cases over the new surface at text scales 1.0,
  1.3, 1.75 and 2.0 across widths of 80 to 240 px.

## 0.1.0

- Initial release.

Features:

- `StatCard`: an overflow-safe dashboard stat card with a value, label, optional
  icon, unit suffix and trend badge, plus `StatCard.compact` and
  `StatCard.loading` presets.
- Seven overflow strategies: `wrap`, `ellipsis`, `tooltip`, `shrink`,
  `shrinkThenWrap` (default), `shrinkThenTooltip` and `scroll`.
- Binary-search text fitting that measures with the ambient
  `MediaQuery.textScalerOf(context)`, so accessibility text scaling shrinks or
  wraps instead of overflowing. Results are cached per text, constraint, scaler
  and style.
- Tooltips are attached only when the text was actually truncated.
- Four layouts: `iconLeading`, `iconTrailing`, `iconAbove` and `noIcon`.
- Three-level theming through `StatCardThemeData` as a `ThemeExtension`, a
  `StatCardTheme` inherited scope, and a per-widget override, merged field by
  field over a fallback derived from `ColorScheme` and `TextTheme`.
- `StatCardGrid`: a responsive grid driven by `minCardWidth`, safe from 240 px
  to 2000 px.
- `StatTrend` with up, down and flat directions and per-instance colour
  overrides.
- Loading skeletons animated with a plain `AnimationController` that respect
  `MediaQuery.disableAnimations`.
- Single-node semantics per card, RTL-aware padding and alignment.
- Zero runtime dependencies; supports Android, iOS, web, macOS, Windows and
  Linux.
