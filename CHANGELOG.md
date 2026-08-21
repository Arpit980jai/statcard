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
