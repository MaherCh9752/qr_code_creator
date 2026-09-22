# Free QR Code Creator (Flutter)

A free, unlimited, offline QR code generator for Android, iOS, Web, and
Desktop. No ads, no upsells, no backend — everything renders on-device and
exports to PNG, SVG, or PDF.

## 1. Run it

```bash
flutter pub get
flutter run              # connected device / emulator
flutter run -d chrome    # browser
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
- **Logo** — “Add logo” picks a gallery image; then try Logo size (10–35%),
  Clear-background toggle, Logo shape (square/circle/rounded), and Border
  width + color. Tip: use error correction H with a logo for best scan rates.
- **Advanced** — Quiet zone slider (0–8 modules, 4 recommended per spec),
  Outer-corner-radius slider, Error-correction dropdown (L/M/Q/H).

Dark mode: switch your OS theme — the app follows it automatically.

## 4. Try the exports (preview panel)

1. Enter any content so the preview shows a code.
2. Drag **Export resolution** (300–4000 px).
3. Tap **PNG** (raster at chosen resolution), **SVG (vector)** (infinitely
   scalable, gradients/shapes/logo embedded), or **PDF** (PNG wrapped on A4).
   Each opens the native share sheet to save or send the file.
4. Verify: reopen the PNG/SVG — colors, shapes, quiet zone, and logo must
   match the on-screen preview.

## 5. Project structure

```
lib/
  main.dart                    # app entry + light/dark M3 theme
  screens/home_screen.dart     # state + content forms + export actions
  widgets/design_panel.dart    # Colors / Shapes / Logo / Advanced cards
  widgets/qr_preview.dart      # live preview + high-res PNG capture
  widgets/qr_painter.dart      # CustomPainter matrix + logo (do not alter logic)
  models/qr_content_builder.dart # payload builders (do not alter logic)
  models/qr_style.dart         # style state
  utils/export_utils.dart      # PNG/SVG/PDF + share (do not alter logic)
```

See `PROJECT-STATE.md` for completed work, verification status, and the
staged UI-modernization plan (Stage 2: content forms, Stage 3: preview/export).
