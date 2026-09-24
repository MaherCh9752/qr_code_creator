import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_creator/models/qr_content_builder.dart';
import 'package:qr_code_creator/models/qr_history_entry.dart';
import 'package:qr_code_creator/models/qr_style.dart';
import 'package:qr_code_creator/utils/qr_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('history store round-trip: save then load', () async {
    SharedPreferences.setMockInitialValues({});
    const store = QrHistoryStore();
    expect(await store.load(), isEmpty);

    final entry = QrHistoryEntry.fromCurrent(
      contentType: QrContentType.url,
      payload: 'https://example.com',
      style: QrStyle(),
      fields: {'url': 'example.com'},
    );
    await store.save(entry);

    final loaded = await store.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.payload, 'https://example.com');
    expect(loaded.first.fields['url'], 'example.com');
  });

  test('empty payload is skipped', () async {
    SharedPreferences.setMockInitialValues({});
    const store = QrHistoryStore();
    final entry = QrHistoryEntry.fromCurrent(
      contentType: QrContentType.url,
      payload: '',
      style: QrStyle(),
      fields: const {},
    );
    await store.save(entry);
    expect(await store.load(), isEmpty);
  });
}
