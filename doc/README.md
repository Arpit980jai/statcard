# doc/

Images referenced by the root `README.md` and by the `screenshots:` block in
`pubspec.yaml`.

The README links these by absolute raw URL so that they resolve on both GitHub
and pub.dev:

`https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/images/<file>`

## `images/`

Generated from the widget itself. Regenerate them after any visual change:

```sh
flutter test --tags screenshots
```

The generator is `test/tools/generate_screenshots_test.dart`. It loads Roboto
and the full Material Icons from the Flutter SDK's own `material_fonts`
artifact, because the widget tester otherwise paints every glyph as a filled
box — which is what the golden files under `test/golden/goldens/` look like, and
why those are not usable as screenshots.

| File | What it shows |
| --- | --- |
| `overflow-before.png` | A plain `Column` with the same content, running off its 200 px card. |
| `overflow-after.png` | The identical content in a `StatCard`, fitting cleanly. |
| `gallery.png` | A `StatCardGrid` with units, trend badges, sparklines and the `iconAbove` layout. |
| `number-degradation.png` | `StatCard.number` at four widths: `1,250,000` → `1.25M` → `1.2M`. |
| `sync-scope.png` | A row of cards with and without a `StatCardSyncScope`. |
| `dark-mode.png` | The same cards in dark mode. |

Also here, converted from the files that used to live in `assets/`:

| File | Notes |
| --- | --- |
| `interactive-demo.png` | 2048×2048 UI mockup. Not a screenshot of this package. |
| `interactive-demo-2.png` | 378×264 dashboard mockup. Below the ~800 px width worth linking, and not this package. |
| `overflow-before-original.png` | 730×420 theme-comparison graphic. Not an overflowing card, so not used for that slot. |

None of those three depict `adaptive_stat_card`, so the README and the
`screenshots:` block point at the generated images instead.

## `originals/`

The untouched `.jfif` files the converted images above came from. Excluded from
the published archive by `.pubignore`.
