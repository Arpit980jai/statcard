# adaptive_stat_card

**Dashboard stat cards for Flutter that never overflow — with zero runtime dependencies.**

[![pub package](https://img.shields.io/pub/v/adaptive_stat_card.svg)](https://pub.dev/packages/adaptive_stat_card)
[![CI](https://github.com/Arpit980jai/statcard/actions/workflows/ci.yaml/badge.svg)](https://github.com/Arpit980jai/statcard/actions)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## The problem

A stat card is a big number, a label, and maybe an icon. It is the most
copy-pasted widget in Flutter dashboards, and it breaks constantly:

- a long label — `"Total Deliveries Completed This Month"` — gets clipped or throws
  `A RenderFlex overflowed by 37 pixels on the right`;
- a user turns on accessibility text scaling at 1.5x–2.0x and the layout explodes;
- the app is localised, and the German and Hindi strings are far longer than the
  English originals;
- the number grows to `1,248,930` and runs off a narrow phone.

```dart
// Before: overflows the moment the label or the text scale grows.
Column(
  children: [
    Text('1,248,930', style: TextStyle(fontSize: 28)),
    Text('Total Deliveries Completed This Month'),
  ],
)
```

![Overflowing card](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/images/overflow-before.png)

```dart
// After: degrades gracefully, at any width, at any text scale.
StatCard(
  value: '1,248,930',
  label: 'Total Deliveries Completed This Month',
)
```

![StatCard handling the same content](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/images/overflow-after.png)

## Demo

![A grid of stat cards](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/images/gallery.png)

Run the interactive gallery yourself:

```sh
cd example && flutter run
```

## Features

- **Zero runtime dependencies.** Only `flutter` from the SDK. No `auto_size_text`,
  no shimmer package, no `gap`.
- **Accessibility-text-scale safe.** Text is measured with the ambient
  `MediaQuery.textScalerOf(context)`, so a 2.0x text scale shrinks or wraps
  instead of overflowing. This is the single most common bug in competing widgets.
- **Seven overflow strategies**, from plain ellipsis to shrink-then-wrap to a
  horizontally scrollable line — picked per card.
- **Numbers degrade before they shrink.** `StatCard.number` renders `1,250,000`,
  then `1.25M`, then `1.2M`, and only then starts scaling the font down.
- **One size across a row.** Wrap a group in a `StatCardSyncScope` and every card
  converges on the smallest font size any of them needed.
- **Binary-search text fitting.** The largest font size that fits is found in
  eight measurement passes, not by stepping one pixel at a time, and results are
  cached per `(text, width, text scale, style)` in a bounded LRU.
- **Three levels of theming**: a `ThemeExtension`, an inherited `StatCardTheme`
  scope, and a per-widget override — merged field by field.
- **Four layouts**, trend badges, sparklines, loading skeletons, error and empty
  states, and a responsive `StatCardGrid`.
- **RTL and screen-reader ready.** Directional padding throughout, and one
  semantics node per card instead of three.
- **Works everywhere**: Android, iOS, web, macOS, Windows, Linux. Pure Dart, no
  platform channels.

## Install

```sh
flutter pub add adaptive_stat_card
```

Or add it by hand:

```yaml
dependencies:
  adaptive_stat_card: ^0.2.0
```

## Quick start

```dart
import 'package:adaptive_stat_card/adaptive_stat_card.dart';

StatCard(
  value: '1,248',
  label: 'Deliveries this month',
  unit: 'pkg',
  icon: const Icon(Icons.local_shipping_outlined),
  trend: const StatTrend.up('+12.4%'),
  onTap: () => Navigator.pushNamed(context, '/deliveries'),
);
```

## Overflow strategies

Set `overflow:` per card. Every strategy is guaranteed not to throw a layout
overflow.

| Strategy | Behavior | Best for | Result |
| --- | --- | --- | --- |
| `wrap` | Wraps up to `labelMaxLines`, then ellipsis. Font size never changes. | Labels where a consistent font size matters more than seeing every word. | `Total Deliveries` <br> `Completed This…` |
| `ellipsis` | One line, truncated with `…`. | Dense tables and compact cards. | `Total Deliveries C…` |
| `tooltip` | One line with `…`; the full string appears on hover or long press. | Desktop and web dashboards. | `Total Deliveries C…` <br> `↳ tooltip on hover` |
| `shrink` | Scales the font down to `minFontScale` to keep one line. | Big numbers that must stay on one line. | `Total Deliveries Completed` (smaller) |
| `shrinkThenWrap` **(default)** | Shrinks to keep one line; if that is impossible, wraps; then ellipsis. | Almost everything. Preserves the most information. | `Total Deliveries` <br> `Completed This Month` |
| `shrinkThenTooltip` | Shrinks, then truncates, and exposes the full text in a tooltip. | Narrow cards on pointer devices. | `Total Deliveries Compl…` <br> `↳ tooltip on hover` |
| `scroll` | One line at full size inside a horizontal scroll view. Nothing is hidden. | Long unbreakable IDs, hashes, and account numbers. | `◀ Total Deliveries Completed ▶` |

A tooltip is only attached when the text was **actually** truncated — text that
fits never gets a redundant tooltip.

On a touch device `tooltip` and `onTap` do not fight over the gesture: a long
press opens the tooltip without firing `onTap`, and a tap fires `onTap` without
opening the tooltip.

## Numeric values

A number has something a string does not: shorter renderings of itself. Passing
one to `StatCard.number` lets the card **degrade the value before it degrades
the type size** — `1,250,000`, then `1.25M`, then `1.2M`, and only then the
`overflow` chain above.

```dart
StatCard.number(
  1250000,
  label: 'Deliveries this month',
  trend: const StatTrend.up('+12.4%'),
);
```

![The same number at four widths](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/images/number-degradation.png)

| Format | Ladder | Use it when |
| --- | --- | --- |
| `auto` **(default)** | `1,250,000` → `1.25M` → `1.2M` | Almost everything. Shows the most precision the card has room for. |
| `grouped` | `1,250,000` | The exact figure matters and you would rather it shrank than rounded. |
| `compact` | `1.25M` → `1.2M` | The dashboard should read consistently whether or not a card has room. |

Whatever ends up painted, the accessibility label reads the **full** grouped
number, so a screen reader never hears `1.2M`.

Compact digits are truncated, not rounded: `1.25M` shortens to `1.2M`, never to
`1.3M`. A number that loses precision as its card narrows should not look like
it changed, and should never read larger than it is.

### Formatting and localisation

The built-in formatter is **en-style** — `,` groups thousands, `.` is the decimal
separator, and the suffixes are `K`, `M`, `B`, `T`. It is deliberately not
localised, because localising it properly means depending on `intl`, and this
package has no runtime dependencies.

`valueFormatter` is the escape hatch, and is where `intl` belongs. It is handed
the number *and the width actually available*, so it can decide how much to
abbreviate:

```dart
StatCard.number(
  1250000,
  label: 'Lieferungen',
  valueFormatter: (num value, double availableWidth) => availableWidth < 120
      ? NumberFormat.compact(locale: 'de').format(value)
      : NumberFormat.decimalPattern('de').format(value),
);
```

A formatter returns one string rather than a ladder, so the card falls straight
through to the `overflow` chain when its result does not fit.

`StatCardNumberFormat.grouped(...)` and `StatCardNumberFormat.compact(...)` are
public if you want the same strings elsewhere.

### Animated values

`animateValue: true` counts from the old reading to the new one whenever the
value changes:

```dart
StatCard.number(deliveries, label: 'Deliveries', animateValue: true);
```

It is suppressed when `MediaQuery.disableAnimations` is set, does not animate on
first build, and only ever measures the two endpoints — a count in flight adds
nothing to the shared measurement cache.

## Sparklines

Pass a series and the card draws it under the label. It is a `CustomPainter`, not
a charting dependency:

```dart
StatCard(
  value: '4.2',
  label: 'Revenue',
  unit: 'Cr',
  sparkline: const <double>[3, 5, 4, 9, 7, 12, 11, 15],
);
```

The line is **dropped entirely** — no squeezed smudge, no stolen label space —
when either:

- the series has fewer than two points, or
- the card's content box is narrower than `StatCard.sparklineMinWidth` (96 px,
  which is the card width minus its padding and any icon).

A flat series is drawn down the middle instead of dividing by zero, and
non-finite samples are dropped. Colour and thickness come from the theme's
`sparklineColor` and `sparklineStrokeWidth`.

## StatCardSyncScope

Cards fit their own text, which is right for a card standing alone and wrong for
a row: `1,248,930,551` shrinks to fit while `42` stays huge, and the row looks
broken. Wrap the group in a scope and they converge on the smallest size any of
them needed:

```dart
StatCardSyncScope(
  child: StatCardGrid(
    children: const <StatCard>[
      StatCard(value: '1,248,930,551', label: 'Deliveries'),
      StatCard(value: '42', label: 'Open tickets'),
      StatCard(value: '4.8', label: 'Satisfaction'),
    ],
  ),
);
```

![A row of cards with and without a sync scope](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/images/sync-scope.png)

Values synchronise with values and labels with labels; the two never influence
each other, because they start from different base sizes.

**How it settles.** On the first frame each card fits its text on its own and
reports the size it chose. After that frame the scope takes the minimum per role
and, if it changed, rebuilds its descendants once with that size. Cards always
report the size they *would* have picked unsynchronised, never the size they were
told to paint, so the reported set does not depend on the broadcast and the
minimum is a fixed point — there is no feedback loop to oscillate. Cards may be
added and removed freely; the minimum is recomputed both ways.

A scope therefore costs one extra frame when its contents change. Nothing
flickers in between: the first frame shows correctly fitted, individually sized
cards. Pass `enabled: false` to switch the behaviour off without restructuring
the tree, and with no scope at all every card behaves exactly as it always did.

## Layouts

| Layout | Description |
| --- | --- |
| `iconLeading` **(default)** | Icon before the value/label column, mirrored in RTL. |
| `iconTrailing` | Icon after the column, mirrored in RTL. |
| `iconAbove` | Icon on top, then value, then label. Best for narrow grid cells. |
| `noIcon` | The icon is ignored even if one is supplied. |

```dart
StatCard(
  value: '98',
  label: 'Satisfaction',
  unit: '%',
  icon: const Icon(Icons.thumb_up_outlined),
  layout: StatCardLayout.iconAbove,
);
```

## Card states

A dashboard card is rarely just a number. Four states cover the rest:

| State | What it does |
| --- | --- |
| `isLoading: true` | Renders the pulsing skeleton. Use `StatCard.loading()` when there is no value or label yet. |
| `error: Object?` | Renders an error glyph where the value goes, keeps the label, and exposes `error.toString()` as a tooltip and to screen readers. Takes precedence over `isLoading`. |
| `emptyPlaceholder` | Shown when `value` is empty. Defaults to `—`, so "no reading" is visibly different from "still loading". |
| `selected: true` | Takes the theme's `iconColor` as the border colour and doubles the border width. Announced as selected. |

```dart
StatCard(
  value: snapshot.hasData ? '${snapshot.data}' : '',
  label: 'Deliveries',
  isLoading: snapshot.connectionState == ConnectionState.waiting,
  error: snapshot.error,
  selected: selectedMetric == Metric.deliveries,
  onTap: () => select(Metric.deliveries),
  onLongPress: () => showMetricMenu(context),
);
```

`onLongPress` sits alongside `onTap`; either one alone is enough to make the card
tappable. Note that `StatCardOverflow.tooltip` also uses a long press to reveal
truncated text — when both are in play the tooltip wins for a press landing on
the truncated text itself, and `onLongPress` wins everywhere else on the card.

## Theming

`StatCardThemeData` has three application levels. They are merged **field by
field**, so a theme that sets only `borderRadius` still inherits every fallback
colour. Later levels win:

1. `StatCardThemeData.fallback(context)` — derived from your `ColorScheme` and
   `TextTheme`. Works in light and dark, Material 2 and Material 3, with zero
   configuration.
2. `Theme.of(context).extension<StatCardThemeData>()`
3. The nearest `StatCardTheme` ancestor
4. `StatCard(theme: ...)`

```dart
// 1. App-wide, via ThemeExtension.
MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      StatCardThemeData(borderRadius: 24, elevation: 2),
    ],
  ),
);

// 2. One screen or section.
StatCardTheme(
  data: const StatCardThemeData(backgroundColor: Color(0xFF101827)),
  child: StatCardGrid(children: cards),
);

// 3. One card.
StatCard(
  value: '3',
  label: 'Incidents',
  theme: const StatCardThemeData(borderColor: Colors.red),
);
```

Available fields: `backgroundColor`, `borderColor`, `iconColor`, `upColor`,
`downColor`, `flatColor`, `skeletonBaseColor`, `sparklineColor`,
`sparklineStrokeWidth`, `valueStyle`, `labelStyle`, `unitStyle`, `trendStyle`,
`borderRadius`, `borderWidth`, `elevation`, `iconSize`, `spacing`, `padding`.

## StatCardGrid

A responsive grid with no breakpoint configuration. The column count is
`((maxWidth + spacing) / (minCardWidth + spacing)).floor()`, clamped to at least
one and at most the number of cards. The gaps are counted against the available
width, so a card really is at least `minCardWidth` wide rather than that minus
its share of the spacing.

```dart
StatCardGrid(
  minCardWidth: 180,
  spacing: 12,
  runSpacing: 12,
  children: const <StatCard>[
    StatCard(value: '1,248', label: 'Deliveries'),
    StatCard(value: '312', label: 'Active users'),
    StatCard(value: '18', label: 'Pending pickups'),
  ],
);
```

By default each row sizes itself to its tallest card, which is the safest option
for long labels and large text scales. Pass `childAspectRatio` if you need every
card to be exactly the same shape.

## Accessibility

- Text is measured with the real `TextScaler`, so the layout holds from 1.0x to
  2.0x and beyond. The stress suite asserts this at 1.0x, 1.3x, 1.75x and 2.0x
  across widths of 80–240 px.
- Each card exposes a **single** semantics node reading
  `"<label>: <value><unit>"`; the inner text nodes are excluded so a screen
  reader does not announce the same card three times. Override it with
  `semanticsLabel`.
- A card with `onTap` is announced as a button and exposes a tap action; one with
  `onLongPress` exposes a long-press action, and `selected: true` is announced.
- `StatCard.number` always reads the **full** grouped number, so a card painting
  `1.2M` is still announced as `1,250,000`.
- A card in its error state announces the error rather than a stale value.
- The loading skeleton stops pulsing, and `animateValue` stops counting, when
  `MediaQuery.disableAnimations` is set.
- Sparklines are decorative and are not announced; the trend badge already says
  in words what the line says in pixels.
- Everything uses directional padding and alignment, so RTL locales mirror
  correctly.

## API reference

### `StatCard`

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `String` | required | The headline number, already formatted for display. |
| `label` | `String` | required | The descriptive text under the value. |
| `icon` | `Widget?` | `null` | Any widget; typically an `Icon` or a small image. |
| `unit` | `String?` | `null` | Short suffix next to the value, e.g. `kg`, `%`. |
| `trend` | `StatTrend?` | `null` | Optional delta badge. |
| `sparkline` | `List<double>?` | `null` | Series drawn under the label; omitted below `sparklineMinWidth` or under two points. |
| `overflow` | `StatCardOverflow` | `shrinkThenWrap` | How text degrades when it does not fit. |
| `layout` | `StatCardLayout` | `iconLeading` | Where the icon sits. |
| `labelMaxLines` | `int` | `2` | Maximum lines for the label. |
| `valueMaxLines` | `int` | `1` | Maximum lines for the value. |
| `minFontScale` | `double` | `0.7` | Floor for shrink strategies, as a fraction of the base size. |
| `onTap` | `VoidCallback?` | `null` | When this and `onLongPress` are both null, no `InkWell` is added at all. |
| `onLongPress` | `VoidCallback?` | `null` | Long-press callback; also adds the `InkWell` on its own. |
| `selected` | `bool` | `false` | Draws and announces the card as selected. |
| `error` | `Object?` | `null` | Renders the error state instead of the value; wins over `isLoading`. |
| `emptyPlaceholder` | `String` | `'—'` | Rendered when `value` is empty. |
| `isLoading` | `bool` | `false` | Renders the skeleton instead of the content. |
| `theme` | `StatCardThemeData?` | `null` | Per-instance override, highest precedence. |
| `semanticsLabel` | `String?` | `null` | Overrides the generated accessibility label. |
| `padding` | `EdgeInsetsGeometry?` | `null` | Overrides the theme padding. |

Named constructors: `StatCard.compact(...)` for a dense preset (tighter padding,
single-line label, ellipsis) and `StatCard.loading(...)` for a skeleton-only card
that needs no value or label.

### `StatCard.number`

Takes everything above except `value`, plus:

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `value` | `num` | required, positional | The number to render. Non-finite values fall back to `emptyPlaceholder`. |
| `format` | `StatCardValueFormat` | `auto` | Which ladder to walk: `auto`, `grouped` or `compact`. |
| `valueFormatter` | `String Function(num, double)?` | `null` | Replaces the built-in formatter; receives the number and the available width. |
| `animateValue` | `bool` | `false` | Counts to a new reading; suppressed under `MediaQuery.disableAnimations`. |

Constants: `StatCard.sparklineMinWidth` (`96`), `StatCard.sparklineHeight` (`20`),
`StatCard.valueAnimationDuration` (`400 ms`), `StatCard.valueAnimationCurve`
(`Curves.easeOutCubic`).

### `StatCardSyncScope`

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `child` | `Widget` | required | The subtree whose cards should converge on one size. |
| `enabled` | `bool` | `true` | When false, exactly equivalent to having no scope. |

### `StatCardNumberFormat`

| Member | Returns | Description |
| --- | --- | --- |
| `grouped(num value, {int? fractionDigits})` | `String` | `1,250,000`. Integers lose the decimal point; a double keeps its shortest form. |
| `compact(num value, {int fractionDigits = 2})` | `String` | `1.25M`. Digits are truncated, not rounded. |
| `ladder(num value, StatCardValueFormat format)` | `List<String>` | The ordered renderings `StatCard.number` measures. |

### `StatTrend`

`StatTrend.up(label)`, `StatTrend.down(label)`, `StatTrend.flat(label)`, each
accepting an optional `color:` override. Colours otherwise come from the resolved
theme's `upColor` / `downColor` / `flatColor`.

### Testing helpers

`clearFitCache()` empties the shared measurement cache, `debugFitCacheLength()`
reports how full it is, and `kFitCacheMaxEntries` (`200`) is its bound. Only
useful in tests; the cache evicts its own least recently used entries in
production.

## FAQ

**Why not `auto_size_text`?**
`auto_size_text` resizes one string. This package solves the whole card: the
relationship between the value and the label, the unit that has to stay baseline
aligned with the number, the icon competing for horizontal space, the trend badge
that has to survive a 90 px card, and the text scaler that affects all of them at
once. It also does it with **no dependency at all**, which matters if you are
counting the transitive weight of your dashboard screen.

**Does the measurement hurt performance?**
Each fit costs at most eight `TextPainter.layout` calls, and every result is
cached against `(text, width, height, text scaler, style, strategy)`. Rebuilds
with unchanged content do no measurement work. The cache is a 200-entry LRU, so
a dashboard whose numbers change every few seconds cannot grow it without bound,
and an `animateValue` count in flight adds nothing to it at all.

**Why isn't the number formatter localised?**
Because localising it properly means depending on `intl`, and the whole point of
this package is that it depends on nothing. The built-in formatter is en-style;
`valueFormatter` is where you plug `intl` in, and it is handed the available
width so it can decide how much to abbreviate.

**What happens under unbounded width?**
Measurement is meaningless there, so the text renders plainly with an ellipsis
and lets the parent decide. Cards inside a horizontal `ListView` behave sensibly.

**Can I use my own card chrome?**
Set `borderWidth: 0` and `elevation: 0` and give `backgroundColor:
Colors.transparent` in a `StatCardThemeData`, then wrap the card yourself.

## Contributing

Issues and pull requests are welcome at
<https://github.com/Arpit980jai/statcard>.

```sh
flutter pub get
dart format . --set-exit-if-changed
flutter analyze --fatal-infos
flutter test
```

Golden tests are tagged `golden` and are platform-sensitive; CI runs
`flutter test --exclude-tags golden`. Regenerate them locally with
`flutter test --update-goldens`.

## License

MIT © 2026 Arpit Jaiswal. See [LICENSE](LICENSE).
