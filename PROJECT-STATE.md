# PROJECT-STATE — qr_code_creator

Last updated: 2026-09-22 (Stage 1 UI modernization complete)

## What this is
Free, unlimited, offline QR code generator (Flutter, Android/iOS/Web/Desktop).
No backend, no ads, no upsells. All rendering is local via `qr` package matrix
+ `CustomPainter` (PNG/PDF) and a mirrored SVG builder.

## Architecture
```
lib/
  main.dart                      # MaterialApp + light/dark M3 theme (seed: deepPurple)
  screens/home_screen.dart       # state: content type, QrStyle, payload, resolution, export actions
  widgets/design_panel.dart      # Stage 1 extraction: Colors / Shapes / Logo / Advanced cards
  widgets/qr_preview.dart        # live preview + captureAsPng (logic untouched)
  widgets/qr_painter.dart        # CustomPainter matrix + logo (logic frozen per constraints)
  models/qr_content_builder.dart # 11 content-type payload builders (logic frozen)
  models/qr_style.dart           # full style state incl. copyWith({...})
  utils/export_utils.dart        # PNG/SVG/PDF + share sheet (logic frozen)
```

## Completed work
1. **qr ^3.x compat fix** — `QrCode` no longer exposes `isDark`; `buildQrCode`
   now returns `QrImage(QrCode.fromData(...))`. Updated `CustomQrPainter` and
   `QrPreview.qrCode` types. `flutter analyze`: 2 errors → 0.
2. **SVG logo + eye-color parity** — SVG embeds logo as base64 `<image>` with
   shape-aware background clearing + clip; eyes follow body fill unless custom;
   `_colorToHex` preserves alpha (`#RRGGBBAA`); `saveSvgAndShare` uses
   `utf8.encode`. Painter eye logic updated to match.
3. **SVG body-shape parity** — gradients use `userSpaceOnUse` with absolute
   coords (fixes per-dot gradients); `classy` uses a 2-corner `<path>` to
   match `RRect.fromRectAndCorners`.
4. **Style expansion** (`qr_style.dart` + painter + SVG + UI):
   - Split eye colors (`eyeFrameColor`/`eyeBallColor`), gradient angle
     (0–360°) + background gradient, 8 body shapes (square, dots, rounded,
     classy, barsHorizontal, barsVertical, diamond, star), eye stroke
     (0.5–1.5×) + corner (0–2×) ratios, logo shape (square/circle/rounded) +
     border, quiet-zone modules (0–8, default 4), outer corner radius.
   - Fixed `copyWith()` to accept optional overrides.
5. **Stage 1 UI modernization** (behavior-preserving):
   - `main.dart`: light + dark `ThemeData` (M3, `ThemeMode.system`).
   - Extracted `DesignPanel` widget, grouped into Colors / Shapes / Logo /
     Advanced cards; theme-aware swatches (`colorScheme.outline`), `InkWell`
     ripples, `AnimatedSwitcher` on conditional rows only.
   - `home_screen.dart`: `_buildDesignPanel` is a thin wrapper; `_regenerate`,
     `_pickLogo`, export methods, content forms, preview untouched.

## Verification status
- `flutter analyze --no-pub`: 0 errors (only pre-existing
  `DropdownButtonFormField:value` deprecation infos — kept intentionally to
  preserve FormField update semantics).
- `flutter build web --no-pub`: passes.
- Payloads (11 types) + exports (PNG/SVG/PDF) identical by construction —
  no logic files touched in Stage 1. Device/share-sheet run not yet done.

## In progress / next (per staged plan)
- **Stage 2 (not started):** extract `ContentTypeForm`, segmented type picker,
  `AnimatedSwitcher` between forms. Constraint: identical `_regenerate` calls.
- **Stage 3 (not started):** preview/export UI — sticky desktop preview,
  collapsible mobile preview, empty-state illustration + CTA, export success
  Snackbar, responsive shell overflow fix. Constraint: same resolution values,
  same `ExportUtils` calls.

## Known notes
- `DropdownButtonFormField(value:)` deprecation infos are intentional for now.
- `permission_handler` + `image` deps are unused candidates for removal (needs
  owner decision — touches pubspec, so asking first).
- Remote: https://github.com/MaherCh9752/qr_code_creator.git (`main`).
