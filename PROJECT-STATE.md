# PROJECT-STATE — qr_code_creator

Last updated: 2026-09-23 (web export + responsive shell + PDF progress + logo format support)

## What this is
Free, unlimited, offline QR code generator (Flutter, Android/iOS/Web/Desktop).
No backend, no ads, no upsells. All rendering is local via `qr` package matrix
+ `CustomPainter` (PNG/PDF) and a mirrored SVG builder.

## Architecture
```
lib/
  main.dart                      # MaterialApp + light/dark M3 theme (seed: deepPurple)
  screens/home_screen.dart       # state: content type, QrStyle, payload, resolution;
                                 # responsive shell (scrollable wide/narrow branches),
                                 # progress dialog, export actions + error SnackBars
  widgets/design_panel.dart      # Stage 1 extraction: Colors / Shapes / Logo / Advanced cards
  widgets/qr_preview.dart        # live preview + captureAsPng (logo decode guarded)
  widgets/qr_painter.dart        # CustomPainter matrix + logo (logic frozen per constraints)
  models/qr_content_builder.dart # 11 content-type payload builders (logic frozen)
  models/qr_style.dart           # full style state incl. copyWith({...})
  utils/export_utils.dart        # PNG/SVG/PDF; kIsWeb browser download vs share sheet;
                                 # buildPdf via compute (off main isolate) + deliverPdf
  utils/browser_download_html.dart  # web: Blob + anchor download (package:web)
  utils/browser_download_stub.dart  # non-web: no-op (conditional import)
  utils/logo_image.dart          # normalizeLogoBytes: format broadening (ICO largest-frame
                                 # re-encode, Flutter passthrough, package:image fallback)
test/
  logo_image_test.dart           # ICO largest-frame / passthrough / error-path tests
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
6. **Responsive shell overflow fix (Stage 3 partial)** — the wide (>900px)
   branch previously rendered two non-scrollable `Column`s in a `Row`; short
   landscape viewports overflowed with no way to scroll. Both `Expanded`
   panels are now wrapped in their own vertical `SingleChildScrollView`, so
   form and preview scroll independently in landscape/desktop.
7. **Web export support** — all three exports previously funneled through
   `dart:io File` + `path_provider.getTemporaryDirectory()`, which throw on
   web. Each save method now checks `kIsWeb` and triggers a browser download
   (Blob URL + anchor via `package:web`) behind a conditional import
   (`browser_download_html.dart` / `browser_download_stub.dart`); mobile
   keeps the temp-file + share-sheet path. Export failures surface in a
   SnackBar instead of dying silently.
8. **PDF export freeze fix** — rasterizing up to 4000² PNG + assembling the
   PDF are multi-second CPU jobs that blocked the UI thread. Now:
   - modal progress dialog (`_withProgress`) covers generation only (not the
     share sheet), with a frame yield so the spinner animates between steps;
   - page raster capped at 2048px (~370 DPI at the 400pt on-page size —
     print-perfect, 4× faster than 4000px);
   - `buildPdf` runs via `compute` off the main isolate on native (web runs
     inline — no isolates there); `deliverPdf` handles download vs share.
9. **Broad logo format support + ICO largest-frame fix** —
   `normalizeLogoBytes` (`utils/logo_image.dart`):
   - `.ico` always re-encodes to PNG using the **largest embedded frame**,
     chosen by actual decoded pixels (the generic decoder returns frame 0 —
     conventionally 16px — and the ICO directory stores 256 as 0, so
     directory sizes can't be trusted). Fixes "very low res" logos.
   - Flutter-decodable formats (PNG/JPEG/GIF/WebP/BMP) pass through
     unchanged; anything else falls back to `package:image` (TIFF, TGA,
     PSD, …) re-encoded to PNG; undecodable files throw a user-facing
     `FormatException` shown as a SnackBar.
   - Logo picker failures are caught + SnackBar'd; preview logo decode has
     an `onError` guard; Logo card lists supported formats.
10. **Tests** — `test/logo_image_test.dart`: multi-size ICO (256 stored as
    directory 0) → 256×256 output, single-image ICO, PNG passthrough
    (identical bytes), garbage → `FormatException`.

## Verification status
- `flutter analyze`: 0 errors (only pre-existing
  `DropdownButtonFormField:value` deprecation infos — kept intentionally to
  preserve FormField update semantics).
- `flutter test`: 4/4 passing (`test/logo_image_test.dart`).
- `flutter build web`: passes.
- `flutter build bundle` (mobile kernel compile): passes.
- Payload builders and SVG builder untouched this round; PNG capture
  behavior unchanged except the PDF-path raster cap. Device/share-sheet run
  not yet done.

## In progress / next (per staged plan)
- **Stage 2 (not started):** extract `ContentTypeForm`, segmented type picker,
  `AnimatedSwitcher` between forms. Constraint: identical `_regenerate` calls.
- **Stage 3 (partially done):**
  - ✅ responsive shell overflow fix (item 6);
  - ✅ export failure SnackBars;
  - ⬜ sticky desktop preview, collapsible mobile preview,
    empty-state illustration + CTA, export *success* SnackBar.
  Constraint: same resolution values, same `ExportUtils` entry points.

## Known notes
- `DropdownButtonFormField(value:)` deprecation infos are intentional for now.
- `permission_handler` remains an unused candidate for removal (touches
  pubspec, so asking first). `image` is now used (logo normalization).
- Web isolates aren't available, so `compute` only helps native; web relies
  on the 2048px PDF cap + progress dialog to stay responsive.
- Remote: https://github.com/MaherCh9752/qr_code_creator.git (`main`).
