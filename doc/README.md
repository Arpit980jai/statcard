# doc/

Screenshots and recordings referenced by the root `README.md`.

The README links these by absolute raw URL so that the images resolve on both
GitHub and pub.dev:

`https://raw.githubusercontent.com/Arpit980jai/statcard/main/doc/<file>`

| File | What it should show |
| --- | --- |
| `overflow_before.png` | A plain `Column` with the same content, showing the yellow-and-black overflow stripes. |
| `overflow_after.png` | The identical content in a `StatCard`, fitting cleanly. |
| `demo.gif` | The example gallery being driven: width slider, text-scale slider, overflow dropdown. |

Until these files exist and are committed, the README shows broken image icons.
Record them from the example gallery (`cd example && flutter run -d chrome`).
