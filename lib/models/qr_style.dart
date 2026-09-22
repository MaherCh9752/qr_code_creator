import 'dart:typed_data';
import 'package:flutter/material.dart';

enum QrBodyShape {
  square,
  dots,
  rounded,
  classy,
  barsHorizontal,
  barsVertical,
  diamond,
  star,
}

enum QrEyeFrameShape { square, rounded, circle }

enum QrEyeBallShape { square, rounded, circle }

enum QrGradientType { none, linear, radial }

enum QrLogoShape { square, circle, rounded }

/// Every design option needed to fully reproduce (and exceed) the
/// QRCode-Monkey customization panel: colors/gradients, corner (eye) shapes,
/// body dot shapes, and logo embedding.
class QrStyle {
  Color foregroundColor;
  Color backgroundColor;

  // Split eye colors — frame and ball can differ. Used only when
  // [useCustomEyeColor] is true, otherwise eyes follow the body fill.
  Color eyeFrameColor;
  Color eyeBallColor;
  bool useCustomEyeColor;

  QrGradientType gradientType;
  Color gradientColor2;
  // Linear gradient direction in degrees: 0 = left→right, 90 = top→bottom,
  // 45 = top-left→bottom-right (legacy default).
  double gradientAngleDeg;
  // Optional background gradient (same angle as foreground linear).
  bool backgroundGradient;
  Color backgroundGradientColor2;

  QrBodyShape bodyShape;
  QrEyeFrameShape eyeFrameShape;
  QrEyeBallShape eyeBallShape;
  // 0.5–1.5, multiplies the 1-module eye-frame stroke.
  double eyeStrokeRatio;
  // 0–2, multiplies the rounded radii (frame 1.5m, ball 0.9m).
  double eyeCornerRatio;

  Uint8List? logoBytes;
  double logoSizeRatio; // fraction of QR width, e.g. 0.22
  bool removeBackgroundBehindLogo;
  QrLogoShape logoShape;
  // Border width as fraction of logo size (0 = none, up to ~0.08).
  double logoBorderWidth;
  Color logoBorderColor;

  // Quiet-zone margin in modules (spec recommends 4). Included in both
  // PNG and SVG output so codes stay scannable.
  int quietModules;
  // Outer background corner radius as fraction of QR size (0 = square).
  double cornerRadiusRatio;

  /// 'L' ~7%, 'M' ~15%, 'Q' ~25%, 'H' ~30% error correction.
  String errorCorrectionLevel;

  QrStyle({
    this.foregroundColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.eyeFrameColor = const Color(0xFF000000),
    this.eyeBallColor = const Color(0xFF000000),
    this.useCustomEyeColor = false,
    this.gradientType = QrGradientType.none,
    this.gradientColor2 = const Color(0xFF000000),
    this.gradientAngleDeg = 45,
    this.backgroundGradient = false,
    this.backgroundGradientColor2 = const Color(0xFFFFFFFF),
    this.bodyShape = QrBodyShape.square,
    this.eyeFrameShape = QrEyeFrameShape.square,
    this.eyeBallShape = QrEyeBallShape.square,
    this.eyeStrokeRatio = 1.0,
    this.eyeCornerRatio = 1.0,
    this.logoBytes,
    this.logoSizeRatio = 0.22,
    this.removeBackgroundBehindLogo = true,
    this.logoShape = QrLogoShape.square,
    this.logoBorderWidth = 0.0,
    this.logoBorderColor = const Color(0xFFFFFFFF),
    this.quietModules = 4,
    this.cornerRadiusRatio = 0.0,
    this.errorCorrectionLevel = 'M',
  });

  QrStyle copyWith({
    Color? foregroundColor,
    Color? backgroundColor,
    Color? eyeFrameColor,
    Color? eyeBallColor,
    bool? useCustomEyeColor,
    QrGradientType? gradientType,
    Color? gradientColor2,
    double? gradientAngleDeg,
    bool? backgroundGradient,
    Color? backgroundGradientColor2,
    QrBodyShape? bodyShape,
    QrEyeFrameShape? eyeFrameShape,
    QrEyeBallShape? eyeBallShape,
    double? eyeStrokeRatio,
    double? eyeCornerRatio,
    Uint8List? logoBytes,
    double? logoSizeRatio,
    bool? removeBackgroundBehindLogo,
    QrLogoShape? logoShape,
    double? logoBorderWidth,
    Color? logoBorderColor,
    int? quietModules,
    double? cornerRadiusRatio,
    String? errorCorrectionLevel,
  }) =>
      QrStyle(
        foregroundColor: foregroundColor ?? this.foregroundColor,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        eyeFrameColor: eyeFrameColor ?? this.eyeFrameColor,
        eyeBallColor: eyeBallColor ?? this.eyeBallColor,
        useCustomEyeColor: useCustomEyeColor ?? this.useCustomEyeColor,
        gradientType: gradientType ?? this.gradientType,
        gradientColor2: gradientColor2 ?? this.gradientColor2,
        gradientAngleDeg: gradientAngleDeg ?? this.gradientAngleDeg,
        backgroundGradient: backgroundGradient ?? this.backgroundGradient,
        backgroundGradientColor2:
            backgroundGradientColor2 ?? this.backgroundGradientColor2,
        bodyShape: bodyShape ?? this.bodyShape,
        eyeFrameShape: eyeFrameShape ?? this.eyeFrameShape,
        eyeBallShape: eyeBallShape ?? this.eyeBallShape,
        eyeStrokeRatio: eyeStrokeRatio ?? this.eyeStrokeRatio,
        eyeCornerRatio: eyeCornerRatio ?? this.eyeCornerRatio,
        logoBytes: logoBytes ?? this.logoBytes,
        logoSizeRatio: logoSizeRatio ?? this.logoSizeRatio,
        removeBackgroundBehindLogo:
            removeBackgroundBehindLogo ?? this.removeBackgroundBehindLogo,
        logoShape: logoShape ?? this.logoShape,
        logoBorderWidth: logoBorderWidth ?? this.logoBorderWidth,
        logoBorderColor: logoBorderColor ?? this.logoBorderColor,
        quietModules: quietModules ?? this.quietModules,
        cornerRadiusRatio: cornerRadiusRatio ?? this.cornerRadiusRatio,
        errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      );
}
