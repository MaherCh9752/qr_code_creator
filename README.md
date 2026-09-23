# Free QR Code Creator (Flutter)

A free, unlimited, offline QR code generator for Android, iOS, Web, and
Desktop. No ads, no upsells, no backend — everything renders on-device and
exports to PNG, SVG, or PDF.

This README is a hands-on guide: run the app, then walk the sections in
order (content → design → export) to try every feature.

## 1. Run it

```bash
flutter pub get
flutter run              # connected device / emulator
flutter run -d chrome    # browser
flutter test             # logo/ICO normalization tests
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
| Event      | Title + location + start/end dates → calendar event. |
| Crypto     | Pick Bitcoin/Bitcoin Cash/Ethereum/Litecoin/Dash, paste an address, optional amount → payment URI. |

## 3. Try the design panel (step 2: Design)

Open each card and tweak — the preview updates live:

- **Colors** — Foreground / Background swatches; Gradient None/Linear/Radial
  + second color; Linear shows an angle slider (0–360°, 45° = diagonal);
  Background-gradient toggle + second color; Custom-eye-colors toggle reveals
  separate Eye-frame and Eye-ball swatches.
- **Shapes** — Body: square, dots, rounded, classy, barsHorizontal,
  barsVertical, diamond, star. Eye frame / Eye ball: square, rounded, circle.
  Eye-stroke slider (0.5–1.5×) and eye-corner slider (0–2×) fine-tune the
  finder patterns.
- **Logo** — "Add logo" picks an image; supported formats: **PNG, JPEG, GIF,
  WebP, BMP, ICO, TIFF**. Then try Logo size (10–35%), Clear-background
  toggle, Logo shape (square/circle/rounded), and Border width + color.
  - **`.ico` tip:** ICO files bundle several sizes — the app automatically
    uses the **largest** embedded frame (up to 256px). For the sharpest logo
    at high export resolutions, prefer a 256px+ PNG.
  - Unsupported files show a "Could not add logo" SnackBar instead of
    failing silently.
  - Tip: use error correction H with a logo for best scan rates.
- **Advanced** — Quiet zone slider (0–8 modules, 4 recommended per spec),
  Outer-corner-radius slider, Error-correction dropdown (L/M/Q/H).

Dark mode: switch your OS theme — the app follows it automatically.

## 4. Try the exports (preview panel)

1. Enter any content so the preview shows a code.
2. Drag **Export resolution** (300–4000 px).
3. Tap **PNG**, **SVG (vector)**, or **PDF**:

   | Platform | What happens |
   |----------|--------------|
   | Mobile / desktop | Native share sheet opens — save or send the file. |
   | Web | The file downloads straight to your browser (no share sheet). |

   - **PNG** rasters at the chosen resolution.
   - **SVG** is true vector (gradients/shapes/logo embedded) — open it in a
     browser or editor and scale freely.
   - **PDF** wraps the code on an A4 page. A progress spinner shows while it
     generates; the embedded image is capped at 2048px (~370 DPI at print
     size) so it stays fast and print-perfect.
   - On failure (e.g. unsupported file), an error SnackBar explains what
     went wrong instead of freezing.

4. Verify: reopen the PNG/SVG — colors, shapes, quiet zone, and logo must
   match the on-screen preview.

### Web / landscape check

Rotate a device or resize the browser window to landscape (width > 900px):
the form (left) and preview (right) become two side-by-side panels that
**scroll independently** — no overflow stripes, everything reachable.

## 5. Run the tests

```bash
flutter test
```

Covers logo normalization: multi-size ICO → largest frame (256px, even when
the ICO directory stores it as 0), single-image ICO, PNG passthrough, and
the unsupported-file error path.

## 6. Project structure

```
lib/
  main.dart                    # app entry + light/dark M3 theme
  screens/home_screen.dart     # state + content forms + responsive shell + exports
  widgets/design_panel.dart    # Colors / Shapes / Logo / Advanced cards
  widgets/qr_preview.dart      # live preview + high-res PNG capture
  widgets/qr_painter.dart      # CustomPainter matrix + logo (do not alter logic)
  models/qr_content_builder.dart # payload builders (do not alter logic)
  models/qr_style.dart         # style state
  utils/export_utils.dart      # PNG/SVG/PDF; web download vs share; PDF via compute
  utils/browser_download_*.dart # conditional web download helper
  utils/logo_image.dart        # logo format normalization (ICO largest-frame etc.)
test/
  logo_image_test.dart         # logo/ICO normalization tests
```

See `PROJECT-STATE.md` for completed work, verification status, and the
staged UI-modernization plan (Stage 2: content forms, Stage 3: preview/export).
