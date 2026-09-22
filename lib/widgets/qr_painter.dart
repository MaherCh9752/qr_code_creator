import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../models/qr_style.dart';

/// Builds the rendered QR module matrix for [data] at the requested
/// error-correction level. Automatically bumps to 'Q' if a logo is present
/// and the requested level is weaker, so the code stays scannable.
///
/// NOTE (qr ^3.0.2): `QrCode` only holds the encoded data (`moduleCount`,
/// `dataCache`). The actual dark/light matrix (`isDark`) lives on `QrImage`,
/// so we return a `QrImage` here.
QrImage buildQrCode(String data, QrStyle style) {
  int level = switch (style.errorCorrectionLevel) {
    'L' => QrErrorCorrectLevel.L,
    'Q' => QrErrorCorrectLevel.Q,
    'H' => QrErrorCorrectLevel.H,
    _ => QrErrorCorrectLevel.M,
  };
  if (style.logoBytes != null && level < QrErrorCorrectLevel.Q) {
    level = QrErrorCorrectLevel.Q;
  }
  final qrCode = QrCode.fromData(
    data: data,
    errorCorrectLevel: level,
  );
  return QrImage(qrCode);
}

/// Returns which of the 3 finder-pattern ("eye") zones a module belongs to,
/// or -1 if it's a normal data module. Each eye occupies a 7x7 block.
int _eyeZoneOf(int row, int col, int n) {
  bool inTL = row < 7 && col < 7;
  bool inTR = row < 7 && col >= n - 7;
  bool inBL = row >= n - 7 && col < 7;
  if (inTL) return 0;
  if (inTR) return 1;
  if (inBL) return 2;
  return -1;
}

/// Linear gradient endpoints for [angleDeg] (0 = left→right, 90 = top→bottom)
/// covering [rect]. Mirrored in ExportUtils SVG output.
List<Offset> gradientEndpoints(Rect rect, double angleDeg) {
  final rad = angleDeg * math.pi / 180;
  final dx = math.cos(rad), dy = math.sin(rad);
  final half = rect.longestSide / 2;
  final c = rect.center;
  return [c - Offset(dx, dy) * half, c + Offset(dx, dy) * half];
}

class CustomQrPainter extends CustomPainter {
  final QrImage qrCode;
  final QrStyle style;
  final ui.Image? logoImage;

  CustomQrPainter({
    required this.qrCode,
    required this.style,
    this.logoImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = qrCode.moduleCount;
    final q = style.quietModules.clamp(0, 8);
    final total = n + q * 2;
    final m = size.width / total;
    final o = q * m; // quiet-zone offset

    final fullRect = Offset.zero & size;

    // Background (solid or gradient, optionally rounded).
    final bgRadius = size.width * style.cornerRadiusRatio.clamp(0.0, 0.2);
    if (style.backgroundGradient) {
      final pts = gradientEndpoints(fullRect, style.gradientAngleDeg);
      final shader = ui.Gradient.linear(
        pts[0],
        pts[1],
        [style.backgroundColor, style.backgroundGradientColor2],
      );
      final bgPaint = Paint()..shader = shader;
      if (bgRadius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(fullRect, Radius.circular(bgRadius)),
          bgPaint,
        );
      } else {
        canvas.drawRect(fullRect, bgPaint);
      }
    } else {
      final bgPaint = Paint()..color = style.backgroundColor;
      if (bgRadius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(fullRect, Radius.circular(bgRadius)),
          bgPaint,
        );
      } else {
        canvas.drawRect(fullRect, bgPaint);
      }
    }

    // Foreground paint (solid or gradient) for body modules.
    final Paint bodyPaint = Paint();
    if (style.gradientType == QrGradientType.linear) {
      final pts = gradientEndpoints(fullRect, style.gradientAngleDeg);
      bodyPaint.shader = ui.Gradient.linear(
        pts[0],
        pts[1],
        [style.foregroundColor, style.gradientColor2],
      );
    } else if (style.gradientType == QrGradientType.radial) {
      bodyPaint.shader = ui.Gradient.radial(
        fullRect.center,
        fullRect.longestSide / 2,
        [style.foregroundColor, style.gradientColor2],
      );
    } else {
      bodyPaint.color = style.foregroundColor;
    }

    // Eyes: split frame/ball colors when custom, else follow body fill.
    // Must mirror ExportUtils.buildSvg eye logic.
    final Paint eyeFramePaintSrc = Paint();
    final Paint eyeBallPaintSrc = Paint();
    if (style.useCustomEyeColor) {
      eyeFramePaintSrc.color = style.eyeFrameColor;
      eyeBallPaintSrc.color = style.eyeBallColor;
    } else {
      eyeFramePaintSrc.color = bodyPaint.color;
      eyeFramePaintSrc.shader = bodyPaint.shader;
      eyeBallPaintSrc.color = bodyPaint.color;
      eyeBallPaintSrc.shader = bodyPaint.shader;
    }

    // Draw data (non-eye) modules. Bars are merged runs for a cleaner look.
    if (style.bodyShape == QrBodyShape.barsHorizontal) {
      _drawBarsHorizontal(canvas, n, m, o, bodyPaint);
    } else if (style.bodyShape == QrBodyShape.barsVertical) {
      _drawBarsVertical(canvas, n, m, o, bodyPaint);
    } else {
      for (int r = 0; r < n; r++) {
        for (int c = 0; c < n; c++) {
          if (!qrCode.isDark(r, c)) continue;
          if (_eyeZoneOf(r, c, n) != -1) continue;
          _drawModule(canvas, r, c, m, o, bodyPaint, style.bodyShape);
        }
      }
    }

    // Draw the 3 eyes as unified shapes (frame + ball).
    final eyeOrigins = [
      Offset(o, o),
      Offset(o + (n - 7) * m, o),
      Offset(o, o + (n - 7) * m),
    ];
    for (final origin in eyeOrigins) {
      _drawEye(canvas, origin, m, eyeFramePaintSrc, eyeBallPaintSrc, style);
    }

    // Logo
    if (logoImage != null) {
      _drawLogo(canvas, size);
    }
  }

  void _drawBarsHorizontal(
      Canvas canvas, int n, double m, double o, Paint paint) {
    for (int r = 0; r < n; r++) {
      int c = 0;
      while (c < n) {
        if (!qrCode.isDark(r, c) || _eyeZoneOf(r, c, n) != -1) {
          c++;
          continue;
        }
        int start = c;
        while (c < n &&
            qrCode.isDark(r, c) &&
            _eyeZoneOf(r, c, n) == -1) {
          c++;
        }
        final run = c - start;
        final rect = Rect.fromLTWH(
            o + start * m, o + r * m, run * m, m);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(m * 0.5)),
          paint,
        );
      }
    }
  }

  void _drawBarsVertical(Canvas canvas, int n, double m, double o, Paint paint) {
    for (int c = 0; c < n; c++) {
      int r = 0;
      while (r < n) {
        if (!qrCode.isDark(r, c) || _eyeZoneOf(r, c, n) != -1) {
          r++;
          continue;
        }
        int start = r;
        while (r < n &&
            qrCode.isDark(r, c) &&
            _eyeZoneOf(r, c, n) == -1) {
          r++;
        }
        final run = r - start;
        final rect = Rect.fromLTWH(
            o + c * m, o + start * m, m, run * m);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(m * 0.5)),
          paint,
        );
      }
    }
  }

  void _drawModule(Canvas canvas, int r, int c, double m, double o, Paint paint,
      QrBodyShape shape) {
    final rect = Rect.fromLTWH(o + c * m, o + r * m, m, m);
    switch (shape) {
      case QrBodyShape.square:
        canvas.drawRect(rect, paint);
        break;
      case QrBodyShape.barsHorizontal:
      case QrBodyShape.barsVertical:
        // Handled by merged-run painters; fallback to square.
        canvas.drawRect(rect, paint);
        break;
      case QrBodyShape.dots:
        canvas.drawCircle(rect.center, m * 0.48, paint);
        break;
      case QrBodyShape.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(m * 0.04),
              Radius.circular(m * 0.35)),
          paint,
        );
        break;
      case QrBodyShape.classy:
        final rr = RRect.fromRectAndCorners(
          rect.deflate(m * 0.03),
          topLeft: Radius.circular(m * 0.5),
          bottomRight: Radius.circular(m * 0.5),
        );
        canvas.drawRRect(rr, paint);
        break;
      case QrBodyShape.diamond:
        final cx = rect.center.dx, cy = rect.center.dy;
        final rad = m * 0.48;
        final path = Path()
          ..moveTo(cx, cy - rad)
          ..lineTo(cx + rad, cy)
          ..lineTo(cx, cy + rad)
          ..lineTo(cx - rad, cy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case QrBodyShape.star:
        canvas.drawPath(_starPath(rect.center, m * 0.48, m * 0.2), paint);
        break;
    }
  }

  Path _starPath(Offset center, double outer, double inner, {int points = 5}) {
    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final rad = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final p = Offset(
          center.dx + rad * math.cos(a), center.dy + rad * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _drawEye(Canvas canvas, Offset origin, double m, Paint frameSrc,
      Paint ballSrc, QrStyle style) {
    final outer = Rect.fromLTWH(origin.dx, origin.dy, 7 * m, 7 * m);
    final frameStroke =
        (m * style.eyeStrokeRatio).clamp(m * 0.5, m * 1.5);
    final framePaint = Paint()
      ..color = frameSrc.color
      ..shader = frameSrc.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameStroke;
    final frameRect = outer.deflate(frameStroke / 2);
    final corner = style.eyeCornerRatio.clamp(0.0, 2.0);

    switch (style.eyeFrameShape) {
      case QrEyeFrameShape.square:
        canvas.drawRect(frameRect, framePaint);
        break;
      case QrEyeFrameShape.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              frameRect, Radius.circular(m * 1.5 * corner)),
          framePaint,
        );
        break;
      case QrEyeFrameShape.circle:
        canvas.drawCircle(frameRect.center, frameRect.width / 2, framePaint);
        break;
    }

    final ballRect = Rect.fromLTWH(
      origin.dx + 2 * m,
      origin.dy + 2 * m,
      3 * m,
      3 * m,
    );
    final ballPaint = Paint()
      ..color = ballSrc.color
      ..shader = ballSrc.shader
      ..style = PaintingStyle.fill;

    switch (style.eyeBallShape) {
      case QrEyeBallShape.square:
        canvas.drawRect(ballRect, ballPaint);
        break;
      case QrEyeBallShape.rounded:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              ballRect, Radius.circular(m * 0.9 * corner)),
          ballPaint,
        );
        break;
      case QrEyeBallShape.circle:
        canvas.drawCircle(ballRect.center, ballRect.width / 2, ballPaint);
        break;
    }
  }

  void _drawLogo(Canvas canvas, Size size) {
    final logoSize = size.width * style.logoSizeRatio;
    final center = size.center(Offset.zero);

    if (style.removeBackgroundBehindLogo) {
      final pad = logoSize * 0.12;
      final bgPaint = Paint()..color = style.backgroundColor;
      switch (style.logoShape) {
        case QrLogoShape.square:
          final bgRect = Rect.fromCenter(
                  center: center, width: logoSize, height: logoSize)
              .inflate(pad);
          canvas.drawRRect(
            RRect.fromRectAndRadius(bgRect, Radius.circular(pad)),
            bgPaint,
          );
          break;
        case QrLogoShape.circle:
          canvas.drawCircle(center, logoSize / 2 + pad, bgPaint);
          break;
        case QrLogoShape.rounded:
          final bgRect = Rect.fromCenter(
                  center: center, width: logoSize, height: logoSize)
              .inflate(pad);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
                bgRect, Radius.circular(logoSize * 0.22 + pad)),
            bgPaint,
          );
          break;
      }
    }

    final logoRect =
        Rect.fromCenter(center: center, width: logoSize, height: logoSize);
    final src = Rect.fromLTWH(
      0,
      0,
      logoImage!.width.toDouble(),
      logoImage!.height.toDouble(),
    );

    canvas.save();
    switch (style.logoShape) {
      case QrLogoShape.square:
        canvas.clipRect(logoRect);
        break;
      case QrLogoShape.circle:
        canvas.clipPath(Path()..addOval(logoRect));
        break;
      case QrLogoShape.rounded:
        canvas.clipRRect(RRect.fromRectAndRadius(
            logoRect, Radius.circular(logoSize * 0.22)));
        break;
    }
    canvas.drawImageRect(logoImage!, src, logoRect, Paint());
    canvas.restore();

    if (style.logoBorderWidth > 0) {
      final bw = logoSize * style.logoBorderWidth.clamp(0.0, 0.08);
      if (bw > 0) {
        final borderPaint = Paint()
          ..color = style.logoBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = bw;
        switch (style.logoShape) {
          case QrLogoShape.square:
            canvas.drawRect(logoRect, borderPaint);
            break;
          case QrLogoShape.circle:
            canvas.drawCircle(center, logoSize / 2, borderPaint);
            break;
          case QrLogoShape.rounded:
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                  logoRect, Radius.circular(logoSize * 0.22)),
              borderPaint,
            );
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomQrPainter oldDelegate) => true;
}

/// Decodes raw image bytes into a ui.Image usable by CustomQrPainter.
Future<ui.Image> decodeImageBytes(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
