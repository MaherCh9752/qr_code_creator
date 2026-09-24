# PROJECT-STATE — qr_code_creator

Last updated: 2026-09-24 (ContentTypeForm split, responsive breakpoints, M3 theme toggle, a11y pass, export UX, expandable design sections, history)

## What this is
Free, unlimited, offline QR code generator (Flutter, Android/iOS/Web/Desktop).
No backend, no ads, no upsells. All rendering is local via `qr` package matrix
+ `CustomPainter` (PNG/PDF) and a mirrored SVG builder.

## Architecture
```
lib/
  main.dart                      # Stateful M3 app: ColorScheme.fromSeed(deepPurple)
                                 # light+dark, ThemeMode.system default + AppBar toggle
  screens/home_screen.dart       # owns state (type, QrStyle, payload, resolution,
                                 # controllers, wifi/crypto/event); responsive shell
                                 # (phone/tablet/desktop); labeled progress dialog,
                                 # success + friendly-error SnackBars; history hook
  screens/history_screen.dart    # prefs-backed list: reload on tap, delete, clear-all
  widgets/content_type_form.dart # 11 content-type forms, pure UI (props + callbacks)
  widgets/design_panel.dart      # Colors / Shapes / Logo / Advanced as expandable
                                 # ExpansionTiles with inline hints; a11y labels
  widgets/qr_preview.dart        # live preview + captureAsPng (logo decode guarded)
  widgets/qr_painter.dart        # CustomPainter matrix + logo (logic frozen per constraints)
  models/qr_content_builder.dart # 11 content-type payload builders (logic frozen)
  models/qr_style.dart           # full style state incl. copyWith({...}) (untouched)
  models/qr_history_entry.dart   # history record + QrStyle JSON codec (logo excluded)
  utils/export_utils.dart        # PNG/SVG/PDF; kIsWeb browser download vs share sheet;
                                 # buildPdf via compute (off main isolate) + deliverPdf
  utils/browser_download_html.dart  # web: Blob + anchor download (package:web)
  utils/browser_download_stub.dart  # non-web: no-op (conditional import)
  utils/logo_image.dart          # normalizeLogoBytes: format broadening (ICO largest-frame
                                 # re-encode, Flutter passthrough, package:image fallback)
  utils/qr_history_store.dart    # shared_preferences JSON list (qr_history_v1, cap 50)
test/
  logo_image_test.dart           # ICO largest-frame / passthrough / error-path tests
  qr_history_store_test.dart     # prefs round-trip + empty-payload skip
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
10. **Tests (round 1)** — `test/logo_image_test.dart`: multi-size ICO (256 stored as
    directory 0) → 256×256 output, single-image ICO, PNG passthrough
    (identical bytes), garbage → `FormatException`.
11. **ContentTypeForm split** — `home_screen.dart` (~453 → ~340 lines):
    new `widgets/content_type_form.dart` owns the type dropdown + all 11
    forms with identical field keys, keyboards, and `_regenerate` call sites
    (type switch = setState only; wifi/crypto/event = setState + regenerate;
    cancel on date picker still regenerates). HomeScreen keeps all state.
12. **Responsive breakpoints** — `LayoutBuilder` shell: phone <800 stacks
    form → preview in one scroll (content → design → preview); tablet
    800–1199 two-pane flex 5/4; desktop ≥1200 centered maxWidth 1400,
    form maxWidth 720 + `VerticalDivider`, preview pinned top-center in its
    own scroll column. Preview `displaySize` adapts (phone fits, tablet 300,
    desktop 340). Generation/export untouched.
13. **M3 theme toggle** — `main.dart` is now stateful:
    `ColorScheme.fromSeed(deepPurple)` light + dark, `ThemeMode.system`
    default. HomeScreen AppBar cycles system → light → dark with matching
    icon/tooltip. Hardcoded chrome (`grey.shade300`, `Colors.grey` helper
    text) replaced with `outlineVariant` / `onSurfaceVariant`. QR
    foreground/background/eye colors untouched (user design choices).
14. **Accessibility pass (incremental)** — color swatches: `Semantics`
    button + `#RRGGBB` value + hint, 48px hit area (36px visual); all 8
    sliders wrapped in `MergeSemantics` + `semanticFormatterCallback`
    (pixels/degrees/percent/modules/times); progress dialog is a labeled
    `AlertDialog` with `liveRegion`. Remaining: dropdown names, event-tile
    button roles, preview image label, header roles, export-button 48px min.
15. **Export UX feedback** — `_withProgress(work, message:)` shows
    resolution-aware messages (`Generating PNG at N px…`, `Building PDF…`);
    new `_showExportSuccess` (check icon, 3s); `_showExportError` maps
    permission-denied and disk-full to friendly text (4s). Covers generation
    only, not the share sheet. `ExportUtils` generation untouched.
16. **Expandable design sections** — `_SectionCard` is now
    `Card + ExpansionTile` (initially expanded, collapsible) with per-section
    hints (Colors/Shapes/Logo/Advanced) plus `helperText` on error
    correction: "Higher error-correction allows a bigger logo but reduces
    readable area." Every control and `_set → onChanged` path unchanged.
17. **Local history (shared_preferences)** — new `shared_preferences: 2.5.5`
    dep; `models/qr_history_entry.dart` (id/type/label/payload/timestamp/
    resolution/fields/wifi/crypto/events + style JSON minus logoBytes +
    `hasLogo`; tolerant `fromJson`, mutable-list-safe `decodeList`);
    `utils/qr_history_store.dart` (`qr_history_v1`, cap 50, newest-first);
    `screens/history_screen.dart` (reload on tap, delete, clear-all confirm,
    empty/error/loading states). HomeScreen: AppBar History button,
    `await _recordHistory()` right after generation (before share) in all
    three exports, `_applyHistoryEntry` restores type/fields/selections/
    resolution/style then `_regenerate`s + Snackbar (notes logo not stored).
    Bugfix this round: `load()`/`decodeList` returned `const []` so the
    first-ever `save()` threw on `removeWhere` (swallowed) — now mutable;
    covered by `test/qr_history_store_test.dart` (round-trip + empty skip).

## Verification status
- `flutter analyze`: 0 errors (only pre-existing
  `DropdownButtonFormField:value` deprecation infos — kept intentionally to
  preserve FormField update semantics).
- `flutter test`: 6/6 passing (4× `logo_image_test.dart`, 2×
  `qr_history_store_test.dart`).
- `flutter build web`: passes (prior round; rerun before release).
- Payload builders and SVG builder untouched this round; PNG capture
  behavior unchanged except the PDF-path raster cap. Device/share-sheet run
  not yet done.

## In progress / next (per staged plan)
- **Stage 2 (done):** `ContentTypeForm` extracted with identical regenerate
  semantics. Remaining polish (optional): segmented type picker,
  `AnimatedSwitcher` between forms.
- **Stage 3 (mostly done):**
  - ✅ responsive shell + breakpoints + sticky preview;
  - ✅ export failure + success SnackBars + labeled progress;
  - ✅ expandable design sections + hints;
  - ⬜ collapsible mobile preview, empty-state illustration + CTA.
  Constraint: same resolution values, same `ExportUtils` entry points.
- **Accessibility (partial):** color swatches + sliders + progress done;
  next: dropdown names, event tiles, preview label, headers, 48px export buttons.
- **History (v1 done):** logos excluded by design; next if requested:
  file-based logo store (docs dir + path in prefs) instead of base64-in-prefs.

## Known notes
- `DropdownButtonFormField(value:)` deprecation infos are intentional for now.
- `permission_handler` remains an unused candidate for removal (touches
  pubspec, so asking first). `image` is now used (logo normalization).
- Web isolates aren't available, so `compute` only helps native; web relies
  on the 2048px PDF cap + progress dialog to stay responsive.
- History prefs key `qr_history_v1`, cap 50; `logoBytes` excluded — reload
  shows "logo image not stored"; empty payloads are never saved.
- Remote: https://github.com/MaherCh9752/qr_code_creator.git (`main`).
