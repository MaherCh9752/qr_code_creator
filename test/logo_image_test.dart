import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:qr_code_creator/utils/logo_image.dart';

Uint8List _png(int size, {int r = 0, int g = 0, int b = 0}) {
  final image = img.Image(width: size, height: size);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

/// Manually assembles an ICO from PNG blobs. [widthHeightBytes] are the raw
/// directory entries (0 means 256 per the ICO spec).
Uint8List _buildIco(List<(Uint8List bytes, int w, int h)> entries) {
  final out = BytesBuilder();
  out.add([0, 0, 1, 0, entries.length & 0xff, 0]); // reserved, type=ico, count
  var offset = 6 + 16 * entries.length;
  for (final (bytes, w, h) in entries) {
    final entry = ByteData(16)
      ..setUint8(0, w)
      ..setUint8(1, h)
      ..setUint8(2, 0) // palette
      ..setUint8(3, 0) // reserved
      ..setUint16(4, 1, Endian.little) // planes
      ..setUint16(6, 32, Endian.little) // bpp
      ..setUint32(8, bytes.length, Endian.little)
      ..setUint32(12, offset, Endian.little);
    out.add(entry.buffer.asUint8List());
    offset += bytes.length;
  }
  for (final (bytes, _, _) in entries) {
    out.add(bytes);
  }
  return out.takeBytes();
}

void main() {
  test('ICO picks the largest frame, not frame 0 (256 stored as 0)', () async {
    // Realistic ordering: smallest first; 256px entry has dir size 0.
    final ico = _buildIco([
      (_png(16, r: 255), 16, 16),
      (_png(48, r: 255, g: 255), 48, 48),
      (_png(256, b: 255), 0, 0), // directory stores 0 for 256
    ]);

    final normalized = await normalizeLogoBytes(ico);
    final decoded = img.decodeImage(normalized);

    expect(decoded, isNotNull);
    expect(decoded!.width, 256);
    expect(decoded.height, 256);
  });

  test('single-image ICO still decodes', () async {
    final ico = _buildIco([(_png(32, g: 255), 32, 32)]);
    final normalized = await normalizeLogoBytes(ico);
    final decoded = img.decodeImage(normalized);
    expect(decoded!.width, 32);
  });

  test('regular PNG passes through untouched', () async {
    final png = _png(64, r: 10, g: 20, b: 30);
    final normalized = await normalizeLogoBytes(png);
    expect(identical(normalized, png), isTrue);
  });

  test('garbage bytes throw FormatException with a helpful message', () async {
    expect(
      () => normalizeLogoBytes(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8])),
      throwsA(isA<FormatException>()),
    );
  });
}
