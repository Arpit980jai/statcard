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

![Overflowing card](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/overflow_before.png)

```dart
// After: degrades gracefully, at any width, at any text scale.
StatCard(
  value: '1,248,930',
  label: 'Total Deliveries Completed This Month',
)
```

![StatCard handling the same content](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/overflow_after.png)

## Demo

![Interactive demo](https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/demo.gif)

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
- **Binary-search text fitting.** The largest font size that fits is found in
  eight measurement passes, not by stepping one pixel at a time, and results are
  cached per `(text, width, text scale, style)`.
- **Three levels of theming**: a `ThemeExtension`, an inherited `StatCardTheme`
  scope, and a per-widget override — merged field by field.
- **Four layouts**, trend badges, loading skeletons, and a responsive
  `StatCardGrid`.
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
  adaptive_stat_card: ^0.1.0
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
`downColor`, `flatColor`, `skeletonBaseColor`, `valueStyle`, `labelStyle`,
`unitStyle`, `trendStyle`, `borderRadius`, `borderWidth`, `elevation`,
`iconSize`, `spacing`, `padding`.

## StatCardGrid

A responsive grid with no breakpoint configuration. The column count is
`(maxWidth / minCardWidth).floor()`, clamped to at least one and at most the
number of cards.

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
- A card with `onTap` is announced as a button and exposes a tap action.
- The loading skeleton stops pulsing when `MediaQuery.disableAnimations` is set.
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
| `overflow` | `StatCardOverflow` | `shrinkThenWrap` | How text degrades when it does not fit. |
| `layout` | `StatCardLayout` | `iconLeading` | Where the icon sits. |
| `labelMaxLines` | `int` | `2` | Maximum lines for the label. |
| `valueMaxLines` | `int` | `1` | Maximum lines for the value. |
| `minFontScale` | `double` | `0.7` | Floor for shrink strategies, as a fraction of the base size. |
| `onTap` | `VoidCallback?` | `null` | When null, no `InkWell` is added at all. |
| `isLoading` | `bool` | `false` | Renders the skeleton instead of the content. |
| `theme` | `StatCardThemeData?` | `null` | Per-instance override, highest precedence. |
| `semanticsLabel` | `String?` | `null` | Overrides the generated accessibility label. |
| `padding` | `EdgeInsetsGeometry?` | `null` | Overrides the theme padding. |

Named constructors: `StatCard.compact(...)` for a dense preset (tighter padding,
single-line label, ellipsis) and `StatCard.loading(...)` for a skeleton-only card
that needs no value or label.

### `StatTrend`

`StatTrend.up(label)`, `StatTrend.down(label)`, `StatTrend.flat(label)`, each
accepting an optional `color:` override. Colours otherwise come from the resolved
theme's `upColor` / `downColor` / `flatColor`.

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
with unchanged content do no measurement work.

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
