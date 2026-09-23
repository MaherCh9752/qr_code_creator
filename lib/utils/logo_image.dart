import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../widgets/qr_painter.dart' show decodeImageBytes;

/// Accepts logo bytes in any format the device picker returns and normalizes
/// them to something the app can decode everywhere (preview, painter, SVG
/// export):
///
/// 1. `.ico` files are re-encoded to PNG via `package:image`, always using
///    the *largest* frame the file contains. ICOs bundle several sizes
///    (16/32/48/256...) conventionally ordered smallest-first, and the
///    generic decoder returns frame 0 — which made logos look pixelated.
///    Largest is chosen by actual decoded pixels, not the directory entry,
///    because 256px entries store 0 in the directory per the ICO spec.
///    (ICO data URIs also don't render in SVG exports, so PNG is required
///    there regardless.)
/// 2. Otherwise, if Flutter's own codec accepts the bytes (PNG/JPEG/GIF/
///    WebP/BMP/...), they are kept as-is — same behavior as before.
/// 3. Otherwise, `package:image` is tried (TIFF, TGA, PSD, ...), which also
///    re-encodes to PNG.
///
/// Throws [FormatException] with a user-facing message if nothing can decode
/// the file.
Future<Uint8List> normalizeLogoBytes(Uint8List bytes) async {
  if (_isIco(bytes)) {
    final largest = _decodeIcoLargest(bytes);
    if (largest != null) {
      return Uint8List.fromList(img.encodePng(largest));
    }
    // Corrupt or unsupported ICO directory — fall through to the generic
    // decoders below; they may still recover something usable.
  } else {
    try {
      final decoded = await decodeImageBytes(bytes);
      decoded.dispose();
      return bytes;
    } catch (_) {
      // Fall through to the package:image decoder.
    }
  }

  final converted = img.decodeImage(bytes);
  if (converted != null) {
    return Uint8List.fromList(img.encodePng(converted));
  }

  // Last resort: Flutter's codec may still accept the file even if
  // package:image couldn't — better to show it than reject it outright.
  try {
    final decoded = await decodeImageBytes(bytes);
    decoded.dispose();
    return bytes;
  } catch (_) {
    throw const FormatException(
        'Unsupported image format. Supported: PNG, JPEG, GIF, WebP, BMP, ICO, TIFF.');
  }
}

bool _isIco(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x00 &&
    bytes[1] == 0x00 &&
    bytes[2] == 0x01 &&
    bytes[3] == 0x00;

/// Decodes every frame in [bytes] and returns the one with the most pixels.
img.Image? _decodeIcoLargest(Uint8List bytes) {
  final decoder = img.IcoDecoder();
  if (decoder.startDecode(bytes) == null) return null;
  img.Image? largest;
  for (var i = 0; i < decoder.numFrames(); i++) {
    final frame = decoder.decodeFrame(i);
    if (frame == null) continue;
    if (largest == null ||
        frame.width * frame.height > largest.width * largest.height) {
      largest = frame;
    }
  }
  return largest;
}
