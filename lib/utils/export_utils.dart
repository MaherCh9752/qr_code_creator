import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/qr_style.dart';
import '../widgets/qr_painter.dart';
import 'browser_download_html.dart'
    if (dart.library.io) 'browser_download_stub.dart' as browser_download;

class ExportUtils {
  static Future<File> _writeTemp(String filename, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> savePngAndShare(Uint8List pngBytes,
      {String filename = 'qrcode.png'}) async {
    if (kIsWeb) {
      browser_download.downloadBytes(pngBytes, filename, 'image/png');
      return;
    }
    final file = await _writeTemp(filename, pngBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'My QR Code');
  }

  /// Builds a fully vector SVG string that mirrors exactly what the
  /// CustomQrPainter draws (colors/gradients, body shape, eye shapes,
  /// quiet-zone, logo).
  static String buildSvg(String data, QrStyle style, {int size = 1000}) {
    final qrCode = buildQrCode(data, style);
    final n = qrCode.moduleCount;
    final q = style.quietModules.clamp(0, 8);
    final total = n + q * 2;
    final m = size / total;
    final o = q * m;

    final buffer = StringBuffer();
    buffer.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="$size" height="$size" viewBox="0 0 $size $size">');

    // Foreground gradient (global userSpaceOnUse to match painter).
    String fillRef = _colorToHex(style.foregroundColor);
    if (style.gradientType != QrGradientType.none) {
      final c1 = _colorToHex(style.foregroundColor);
      final c2 = _colorToHex(style.gradientColor2);
      if (style.gradientType == QrGradientType.linear) {
        final pts = _svgGradientEndpoints(size.toDouble(), style.gradientAngleDeg);
        buffer.writeln('<defs><linearGradient id="grad" gradientUnits="userSpaceOnUse" x1="${pts[0]}" y1="${pts[1]}" x2="${pts[2]}" y2="${pts[3]}">'
            '<stop offset="0%" stop-color="$c1"/><stop offset="100%" stop-color="$c2"/></linearGradient></defs>');
      } else {
        final half = size / 2;
        buffer.writeln('<defs><radialGradient id="grad" gradientUnits="userSpaceOnUse" cx="$half" cy="$half" r="$half">'
            '<stop offset="0%" stop-color="$c1"/><stop offset="100%" stop-color="$c2"/></radialGradient></defs>');
      }
      fillRef = 'url(#grad)';
    }

    // Background (solid or gradient, optionally rounded).
    final bgRx = size * style.cornerRadiusRatio.clamp(0.0, 0.2);
    final bgRxAttr = bgRx > 0 ? ' rx="$bgRx"' : '';
    if (style.backgroundGradient) {
      final c1 = _colorToHex(style.backgroundColor);
      final c2 = _colorToHex(style.backgroundGradientColor2);
      final pts =
          _svgGradientEndpoints(size.toDouble(), style.gradientAngleDeg);
      buffer.writeln('<defs><linearGradient id="bgGrad" gradientUnits="userSpaceOnUse" x1="${pts[0]}" y1="${pts[1]}" x2="${pts[2]}" y2="${pts[3]}">'
          '<stop offset="0%" stop-color="$c1"/><stop offset="100%" stop-color="$c2"/></linearGradient></defs>');
      buffer.writeln(
          '<rect width="$size" height="$size"$bgRxAttr fill="url(#bgGrad)"/>');
    } else {
      buffer.writeln(
          '<rect width="$size" height="$size"$bgRxAttr fill="${_colorToHex(style.backgroundColor)}"/>');
    }

    // Data modules.
    if (style.bodyShape == QrBodyShape.barsHorizontal) {
      for (int r = 0; r < n; r++) {
        int c = 0;
        while (c < n) {
          if (!qrCode.isDark(r, c) || _eyeZoneOfPublic(r, c, n) != -1) {
            c++;
            continue;
          }
          final start = c;
          while (c < n &&
              qrCode.isDark(r, c) &&
              _eyeZoneOfPublic(r, c, n) == -1) {
            c++;
          }
          final run = c - start;
          final rx = o + start * m, ry = o + r * m;
          buffer.writeln('<rect x="$rx" y="$ry" width="${run * m}" height="$m" rx="${m * 0.5}" fill="$fillRef"/>');
        }
      }
    } else if (style.bodyShape == QrBodyShape.barsVertical) {
      for (int c = 0; c < n; c++) {
        int r = 0;
        while (r < n) {
          if (!qrCode.isDark(r, c) || _eyeZoneOfPublic(r, c, n) != -1) {
            r++;
            continue;
          }
          final start = r;
          while (r < n &&
              qrCode.isDark(r, c) &&
              _eyeZoneOfPublic(r, c, n) == -1) {
            r++;
          }
          final run = r - start;
          final rx = o + c * m, ry = o + start * m;
          buffer.writeln('<rect x="$rx" y="$ry" width="$m" height="${run * m}" rx="${m * 0.5}" fill="$fillRef"/>');
        }
      }
    } else {
      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          if (!qrCode.isDark(r, c)) continue;
          if (_eyeZoneOfPublic(r, c, n) != -1) continue;
          final x = o + c * m, y = o + r * m;
          switch (style.bodyShape) {
            case QrBodyShape.square:
              buffer.writeln(
                  '<rect x="$x" y="$y" width="$m" height="$m" fill="$fillRef"/>');
              break;
            case QrBodyShape.barsHorizontal:
            case QrBodyShape.barsVertical:
              buffer.writeln(
                  '<rect x="$x" y="$y" width="$m" height="$m" fill="$fillRef"/>');
              break;
            case QrBodyShape.dots:
              buffer.writeln(
                  '<circle cx="${x + m / 2}" cy="${y + m / 2}" r="${m * 0.48}" fill="$fillRef"/>');
              break;
            case QrBodyShape.rounded:
              buffer.writeln(
                  '<rect x="${x + m * 0.04}" y="${y + m * 0.04}" width="${m * 0.92}" height="${m * 0.92}" rx="${m * 0.35}" fill="$fillRef"/>');
              break;
            case QrBodyShape.classy:
              final cx0 = x + m * 0.03, cy0 = y + m * 0.03;
              final cs = m * 0.94;
              var cr = m * 0.5;
              if (cr > cs / 2) cr = cs / 2;
              final cx1 = cx0 + cs, cy1 = cy0 + cs;
              buffer.writeln('<path d="M ${cx0 + cr} $cy0 H $cx1 V ${cy1 - cr} '
                  'A $cr $cr 0 0 1 ${cx1 - cr} $cy1 H $cx0 V ${cy0 + cr} '
                  'A $cr $cr 0 0 1 ${cx0 + cr} $cy0 Z" fill="$fillRef"/>');
              break;
            case QrBodyShape.diamond:
              final cx = x + m / 2, cy = y + m / 2;
              final rad = m * 0.48;
              buffer.writeln(
                  '<polygon points="$cx,${cy - rad} ${cx + rad},$cy $cx,${cy + rad} ${cx - rad},$cy" fill="$fillRef"/>');
              break;
            case QrBodyShape.star:
              buffer.writeln(
                  '<polygon points="${_starPoints(x + m / 2, y + m / 2, m * 0.48, m * 0.2)}" fill="$fillRef"/>');
              break;
          }
        }
      }
    }

    // Eyes — split frame/ball colors when custom, else body fill.
    final frameRef =
        style.useCustomEyeColor ? _colorToHex(style.eyeFrameColor) : fillRef;
    final ballRef =
        style.useCustomEyeColor ? _colorToHex(style.eyeBallColor) : fillRef;
    final origins = [
      [o, o],
      [o + (n - 7) * m, o],
      [o, o + (n - 7) * m],
    ];
    for (final e in origins) {
      _svgEye(buffer, e[0], e[1], m, frameRef, ballRef, style);
    }

    // Logo — mirrors CustomQrPainter._drawLogo.
    final logoBytes = style.logoBytes;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      final logoSize = size * style.logoSizeRatio;
      final cx = size / 2, cy = size / 2;
      final lx = cx - logoSize / 2, ly = cy - logoSize / 2;
      if (style.removeBackgroundBehindLogo) {
        final pad = logoSize * 0.12;
        final bg = _colorToHex(style.backgroundColor);
        switch (style.logoShape) {
          case QrLogoShape.square:
            final bx = lx - pad, by = ly - pad, bs = logoSize + pad * 2;
            buffer.writeln(
                '<rect x="$bx" y="$by" width="$bs" height="$bs" rx="$pad" fill="$bg"/>');
            break;
          case QrLogoShape.circle:
            buffer.writeln(
                '<circle cx="$cx" cy="$cy" r="${logoSize / 2 + pad}" fill="$bg"/>');
            break;
          case QrLogoShape.rounded:
            final bx = lx - pad, by = ly - pad, bs = logoSize + pad * 2;
            buffer.writeln(
                '<rect x="$bx" y="$by" width="$bs" height="$bs" rx="${logoSize * 0.22 + pad}" fill="$bg"/>');
            break;
        }
      }
      final mime = _logoMimeType(logoBytes);
      final b64 = base64Encode(logoBytes);
      final dataUrl = 'data:$mime;base64,$b64';
      // Clip logo to shape so circle/rounded match the PNG preview.
      final clipId =
          'logoClip${logoSize.round()}${style.logoShape.name}';
      switch (style.logoShape) {
        case QrLogoShape.square:
          break;
        case QrLogoShape.circle:
          buffer.writeln(
              '<defs><clipPath id="$clipId"><circle cx="$cx" cy="$cy" r="${logoSize / 2}"/></clipPath></defs>');
          break;
        case QrLogoShape.rounded:
          buffer.writeln(
              '<defs><clipPath id="$clipId"><rect x="$lx" y="$ly" width="$logoSize" height="$logoSize" rx="${logoSize * 0.22}"/></clipPath></defs>');
          break;
      }
      final clip =
          style.logoShape == QrLogoShape.square ? '' : ' clip-path="url(#$clipId)"';
      buffer.writeln(
          '<image x="$lx" y="$ly" width="$logoSize" height="$logoSize"$clip href="$dataUrl" xlink:href="$dataUrl" preserveAspectRatio="xMidYMid slice"/>');
      if (style.logoBorderWidth > 0) {
        final bw = logoSize * style.logoBorderWidth.clamp(0.0, 0.08);
        if (bw > 0) {
          final bc = _colorToHex(style.logoBorderColor);
          switch (style.logoShape) {
            case QrLogoShape.square:
              buffer.writeln(
                  '<rect x="$lx" y="$ly" width="$logoSize" height="$logoSize" fill="none" stroke="$bc" stroke-width="$bw"/>');
              break;
            case QrLogoShape.circle:
              buffer.writeln(
                  '<circle cx="$cx" cy="$cy" r="${logoSize / 2}" fill="none" stroke="$bc" stroke-width="$bw"/>');
              break;
            case QrLogoShape.rounded:
              buffer.writeln(
                  '<rect x="$lx" y="$ly" width="$logoSize" height="$logoSize" rx="${logoSize * 0.22}" fill="none" stroke="$bc" stroke-width="$bw"/>');
              break;
          }
        }
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static List<double> _svgGradientEndpoints(double size, double angleDeg) {
    final rad = angleDeg * math.pi / 180;
    final dx = math.cos(rad), dy = math.sin(rad);
    final half = size / 2;
    final cx = size / 2, cy = size / 2;
    return [cx - dx * half, cy - dy * half, cx + dx * half, cy + dy * half];
  }

  static String _starPoints(double cx, double cy, double outer, double inner,
      {int points = 5}) {
    final parts = <String>[];
    for (int i = 0; i < points * 2; i++) {
      final rad = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      parts.add('${cx + rad * math.cos(a)},${cy + rad * math.sin(a)}');
    }
    return parts.join(' ');
  }

  static void _svgEye(StringBuffer buffer, double ox, double oy, double m,
      String frameRef, String ballRef, QrStyle style) {
    final frameStroke =
        (m * style.eyeStrokeRatio).clamp(m * 0.5, m * 1.5).toDouble();
    final corner = style.eyeCornerRatio.clamp(0.0, 2.0).toDouble();
    final outerSize = 7 * m;
    final frameRect = [
      ox + frameStroke / 2,
      oy + frameStroke / 2,
      outerSize - frameStroke,
      outerSize - frameStroke
    ];
    switch (style.eyeFrameShape) {
      case QrEyeFrameShape.square:
        buffer.writeln(
            '<rect x="${frameRect[0]}" y="${frameRect[1]}" width="${frameRect[2]}" height="${frameRect[3]}" fill="none" stroke="$frameRef" stroke-width="$frameStroke"/>');
        break;
      case QrEyeFrameShape.rounded:
        buffer.writeln(
            '<rect x="${frameRect[0]}" y="${frameRect[1]}" width="${frameRect[2]}" height="${frameRect[3]}" rx="${m * 1.5 * corner}" fill="none" stroke="$frameRef" stroke-width="$frameStroke"/>');
        break;
      case QrEyeFrameShape.circle:
        final cx = ox + outerSize / 2, cy = oy + outerSize / 2;
        buffer.writeln(
            '<circle cx="$cx" cy="$cy" r="${frameRect[2] / 2}" fill="none" stroke="$frameRef" stroke-width="$frameStroke"/>');
        break;
    }
    final ballX = ox + 2 * m, ballY = oy + 2 * m, ballSize = 3 * m;
    switch (style.eyeBallShape) {
      case QrEyeBallShape.square:
        buffer.writeln(
            '<rect x="$ballX" y="$ballY" width="$ballSize" height="$ballSize" fill="$ballRef"/>');
        break;
      case QrEyeBallShape.rounded:
        buffer.writeln(
            '<rect x="$ballX" y="$ballY" width="$ballSize" height="$ballSize" rx="${m * 0.9 * corner}" fill="$ballRef"/>');
        break;
      case QrEyeBallShape.circle:
        buffer.writeln(
            '<circle cx="${ballX + ballSize / 2}" cy="${ballY + ballSize / 2}" r="${ballSize / 2}" fill="$ballRef"/>');
        break;
    }
  }

  static int _eyeZoneOfPublic(int row, int col, int n) {
    if (row < 7 && col < 7) return 0;
    if (row < 7 && col >= n - 7) return 1;
    if (row >= n - 7 && col < 7) return 2;
    return -1;
  }

  static String _colorToHex(c) {
    final hex = c.value.toRadixString(16).padLeft(8, '0');
    final alpha = hex.substring(0, 2);
    final rgb = hex.substring(2);
    if (alpha == 'ff') return '#$rgb';
    return '#$rgb$alpha';
  }

  static String _logoMimeType(Uint8List bytes) {
    if (bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return 'image/png';
  }

  static Future<void> saveSvgAndShare(String svgContent,
      {String filename = 'qrcode.svg'}) async {
    final bytes = Uint8List.fromList(utf8.encode(svgContent));
    if (kIsWeb) {
      browser_download.downloadBytes(bytes, filename, 'image/svg+xml');
      return;
    }
    final file = await _writeTemp(filename, bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'My QR Code (vector)');
  }

  /// Wraps a high-res PNG render into a single-page A4 PDF. Static and
  /// async so it can run through [compute] off the main isolate (native),
  /// keeping the UI responsive while the document is assembled.
  static Future<Uint8List> buildPdf(Uint8List pngBytes) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(pngBytes);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Image(image, width: 400, height: 400),
        ),
      ),
    );
    return doc.save();
  }

  /// Delivers an already-built PDF (browser download on web, share sheet
  /// elsewhere). Kept separate from [buildPdf] so progress UI can cover only
  /// the heavy generation step.
  static Future<void> deliverPdf(Uint8List pdfBytes,
      {String filename = 'qrcode.pdf'}) async {
    if (kIsWeb) {
      browser_download.downloadBytes(pdfBytes, filename, 'application/pdf');
      return;
    }
    final file = await _writeTemp(filename, pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: 'My QR Code (PDF)');
  }

  /// Convenience wrapper: build + deliver in one call.
  static Future<void> savePdfAndShare(Uint8List pngBytes,
      {String filename = 'qrcode.pdf'}) async {
    final pdfBytes = await compute(buildPdf, pngBytes);
    await deliverPdf(pdfBytes, filename: filename);
  }
}
