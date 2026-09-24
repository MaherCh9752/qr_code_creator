# Free QR Code Creator (Flutter)

A free, unlimited, offline QR code generator for Android, iOS, Web, and
Desktop. No ads, no upsells, no backend — everything renders on-device and
exports to PNG, SVG, or PDF.

This README is a hands-on guide: run the app, then walk the sections in
order to try every feature.

## 1. Run it

```bash
flutter pub get
flutter run              # connected device / emulator
flutter run -d chrome    # browser
flutter run -d windows   # desktop (share sheet may be unavailable — history still saves)
flutter test             # 6 tests: logo/ICO normalization + history store
```

Requires Flutter 3.19+ (Dart 3+). No API keys needed.

## 2. Try the content types (step 1: Content)

Pick a type from the dropdown, fill the fields, and watch the live preview
update instantly. Type something in any field — an empty form shows the
empty-state placeholder instead of a code.

| Type       | How to try it |
|------------|---------------|
| URL        | Enter `flutter.dev` → code encodes `https://flutter.dev` (scheme auto-added). |
| Text       | Enter any sentence → encoded as-is. |
| Email      | To `a@b.com`, subject + body → `mailto:` link; scan to open your mail app. |
| Phone      | Enter `+123456789` → `tel:` link. |
| SMS        | Number + message → `sms:` link with prefilled body. |
| WhatsApp   | Number with country code + message → `https://wa.me/...` link. |
| WiFi       | SSID + password + WPA/WEP/open → `WIFI:` code; scan to join. |
| vCard      | First/last name + phone/email/org → contact card; scan to save contact. |
| Location   | Latitude + longitude (e.g. `48.8584`, `2.2945`) → `geo:` pin. |
| Event      | Title + location + start/end dates (calendar pickers) → calendar event. |
| Crypto     | Pick Bitcoin/Bitcoin Cash/Ethereum/Litecoin/Dash, paste an address, optional amount → payment URI. |

Switching types keeps your other fields (controllers are per-field), so you
can flip between types without losing input.

## 3. Try the design panel (step 2: Design)

Four collapsible sections (all expanded by default — tap a header to
collapse). The preview updates live:

- **Colors** — Foreground / Background swatches (48px targets, screen-reader
  labels with hex value); Gradient None/Linear/Radial + second color; Linear
  shows an angle slider (0–360°); Background-gradient toggle + second color;
  Custom-eye-colors toggle reveals separate Eye-frame and Eye-ball swatches.
  Hint: dark modules on a light background scan most reliably.
- **Shapes** — Body: square, dots, rounded, classy, barsHorizontal,
  barsVertical, diamond, star. Eye frame / Eye ball: square, rounded, circle.
  Eye-stroke slider (0.5–1.5×) and eye-corner slider (0–2×) fine-tune the
  finder patterns. Hint: square shapes scan most reliably.
- **Logo** — "Add logo" picks an image; supported formats: **PNG, JPEG, GIF,
  WebP, BMP, ICO, TIFF**. Then try Logo size (10–35%), Clear-background
  toggle, Logo shape (square/circle/rounded), and Border width + color.
  - **`.ico` tip:** ICO files bundle several sizes — the app automatically
    uses the **largest** embedded frame (up to 256px). For the sharpest logo
    at high export resolutions, prefer a 256px+ PNG.
  - Unsupported files show a "Could not add logo" SnackBar instead of
    failing silently.
  - Hint: pair large logos with higher error correction (see Advanced).
- **Advanced** — Quiet zone slider (0–8 modules, 4 recommended per spec),
  Outer-corner-radius slider, Error-correction dropdown (L/M/Q/H) with helper
  text: "Higher error-correction allows a bigger logo but reduces readable
  area." Tip: use H with a logo for best scan rates.

## 4. Try theme + responsive layout

- **Theme toggle (AppBar, right side):** cycles System (auto) → Light → Dark.
  The app follows your OS theme by default. App chrome (bar, cards, fields,
  panels) is M3 `ColorScheme.fromSeed(deepPurple)` theme-aware in both modes;
  QR module colors are your design choice and never change with the theme.
- **Breakpoints (`LayoutBuilder`):** phone <800px stacks content → design →
  preview in one scroll; tablet 800–1199px is two-pane (flex 5/4); desktop
  ≥1200px centers maxWidth 1400 with a divider and a pinned preview column.
  Resize the browser or rotate a device: the form scrolls while the preview
  stays visible, so edits show in real time.
- **Screen reader:** color swatches announce name + hex, sliders announce
  name + value in one swipe, progress dialogs are live-region labeled.

## 5. Try the exports (preview panel)

1. Enter any content so the preview shows a code (export buttons stay
   disabled while the payload is empty).
2. Drag **Export resolution** (300–4000 px, announced with units).
3. Tap **PNG**, **SVG (vector)**, or **PDF**:

   | Platform | What happens |
   |----------|--------------|
   | Mobile / desktop | Native share sheet opens — save or send the file. |
   | Web | The file downloads straight to your browser (no share sheet). |

   - A labeled progress dialog shows during generation (`Generating PNG at
     N px…` / `Building PDF…`) — share/download itself isn't covered.
   - On success a check-mark SnackBar confirms (`PNG saved — check share
     sheet or downloads.`).
   - On failure (permission denied, disk full, …) a friendly SnackBar
     explains what to do instead of freezing.
   - **PNG** rasters at the chosen resolution.
   - **SVG** is true vector (gradients/shapes/logo embedded) — open it in a
     browser or editor and scale freely.
   - **PDF** wraps the code on an A4 page; the embedded image is capped at
     2048px (~370 DPI at print size) so it stays fast and print-perfect.

4. Verify: reopen the PNG/SVG — colors, shapes, quiet zone, and logo must
   match the on-screen preview.

## 6. Try history

History saves **on generation** (right after PNG capture / SVG build / PDF
build, before share) so a share-sheet failure can't lose the record. Empty
payloads are never saved.

1. Export any code once (see §5).
2. Tap the AppBar **History** (clock) icon.
3. Browse `type · timestamp · resolution` rows — tap to reload that code
   (type, fields, wifi/crypto/event picks, resolution, and style restore;
   then the form stays editable).
   - Note: logo *images* aren't stored (keeps prefs small) — rows with a
     logo say `logo not stored` and reload shows a matching notice.
4. Swipe-free management: per-row delete, or AppBar broom → Clear-all
   confirm. Storage is `shared_preferences` key `qr_history_v1`, newest 50.

## 7. Run the tests

```bash
flutter test
```

- `logo_image_test.dart` (4): multi-size ICO → largest frame (256px, even
  when the ICO directory stores it as 0), single-image ICO, PNG passthrough,
  unsupported-file error path.
- `qr_history_store_test.dart` (2): prefs save→load round-trip, empty
  payload skipped. (Also guards the fixed `const []` unmodifiable-list bug.)

## 8. Project structure

```
lib/
  main.dart                        # stateful M3 app + theme toggle plumbing
  screens/home_screen.dart         # state owner + responsive shell + export UX + history hook
  screens/history_screen.dart      # history list / reload / delete / clear
  widgets/content_type_form.dart   # 11 content forms (pure UI)
  widgets/design_panel.dart        # expandable Colors/Shapes/Logo/Advanced
  widgets/qr_preview.dart          # live preview + high-res PNG capture
  widgets/qr_painter.dart          # CustomPainter matrix + logo (do not alter logic)
  models/qr_content_builder.dart   # payload builders (do not alter logic)
  models/qr_style.dart             # style state (untouched)
  models/qr_history_entry.dart     # history record + style JSON codec (no logo bytes)
  utils/export_utils.dart          # PNG/SVG/PDF; web download vs share; PDF via compute
  utils/browser_download_*.dart    # conditional web download helper
  utils/logo_image.dart            # logo normalization (ICO largest-frame etc.)
  utils/qr_history_store.dart      # prefs history store (cap 50)
test/
  logo_image_test.dart
  qr_history_store_test.dart
```

See `PROJECT-STATE.md` for completed work, verification status, and next
steps (remaining a11y: dropdown names, event tiles, preview label, headers,
48px export buttons; optional file-based logo store for history).
