import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_history_entry.dart';

/// `shared_preferences`-backed history store (JSON list under one key).
///
/// Choice vs sqflite: records are tiny (type + label + payload + style
/// JSON, no logo bytes), access is whole-list read/write, and prefs works
/// on mobile/desktop/web with no native setup. Generation/export code
/// calls [save] only on successful export — it never reads from here.
class QrHistoryStore {
  static const storageKey = 'qr_history_v1';
  static const maxEntries = 50;

  const QrHistoryStore();

  Future<List<QrHistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <QrHistoryEntry>[];
    final entries = QrHistoryEntry.decodeList(raw);
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> save(QrHistoryEntry entry) async {
    if (entry.payload.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((e) => e.id == entry.id);
    current.insert(0, entry);
    final trimmed = current.length > maxEntries
        ? current.sublist(0, maxEntries)
        : current;
    await prefs.setString(
        storageKey, QrHistoryEntry.encodeList(trimmed));
  }

  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((e) => e.id == id);
    await prefs.setString(
        storageKey, QrHistoryEntry.encodeList(current));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
