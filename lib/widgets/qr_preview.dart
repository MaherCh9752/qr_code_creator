import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import '../models/qr_style.dart';
import 'qr_painter.dart';

/// Displays the live QR preview and exposes [repaintKey] so callers can
/// rasterize it to PNG at any resolution via [captureAsPng].
class QrPreview extends StatefulWidget {
  final String data;
  final QrStyle style;
  final double displaySize;

  const QrPreview({
    super.key,
    required this.data,
    required this.style,
    this.displaySize = 300,
  });

  @override
  State<QrPreview> createState() => QrPreviewState();
}

class QrPreviewState extends State<QrPreview> {
  final GlobalKey repaintKey = GlobalKey();
  ui.Image? _logoImage;
  Uint8List? _lastLogoBytes;

  @override
  void didUpdateWidget(covariant QrPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeLoadLogo();
  }

  @override
  void initState() {
    super.initState();
    _maybeLoadLogo();
  }

  void _maybeLoadLogo() {
    final bytes = widget.style.logoBytes;
    if (bytes == null) {
      _logoImage = null;
      _lastLogoBytes = null;
      return;
    }
    if (identical(bytes, _lastLogoBytes)) return;
    _lastLogoBytes = bytes;
    decodeImageBytes(bytes).then(
      (img) {
        if (mounted) setState(() => _logoImage = img);
      },
      onError: (Object _) {
        // Undecodable logo bytes — preview simply renders without a logo.
      },
    );
  }

  QrImage? get qrCode {
    if (widget.data.isEmpty) return null;
    try {
      return buildQrCode(widget.data, widget.style);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = qrCode;
    if (code == null) {
      return SizedBox(
        width: widget.displaySize,
        height: widget.displaySize,
        child: const Center(child: Text('Enter content to preview')),
      );
    }
    return RepaintBoundary(
      key: repaintKey,
      child: SizedBox(
        width: widget.displaySize,
        height: widget.displaySize,
        child: CustomPaint(
          painter: CustomQrPainter(
            qrCode: code,
            style: widget.style,
            logoImage: widget.style.logoBytes != null ? _logoImage : null,
          ),
        ),
      ),
    );
  }

  /// Rasterizes the current preview at [pixelSize] x [pixelSize] pixels,
  /// regardless of the on-screen display size — this is how we offer
  /// unlimited print-quality resolution.
  Future<Uint8List> captureAsPng(int pixelSize) async {
    final code = qrCode!;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = CustomQrPainter(
      qrCode: code,
      style: widget.style,
      logoImage: widget.style.logoBytes != null ? _logoImage : null,
    );
    painter.paint(canvas, Size(pixelSize.toDouble(), pixelSize.toDouble()));
    final picture = recorder.endRecording();
    final img = await picture.toImage(pixelSize, pixelSize);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
