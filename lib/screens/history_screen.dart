import 'package:flutter/material.dart';
import '../models/qr_content_builder.dart';
import '../models/qr_history_entry.dart';
import '../utils/qr_history_store.dart';

/// Lists locally saved QR records. Tap to pop back with the selected
/// entry so HomeScreen can reload it. Delete/clear only touch prefs.
class HistoryScreen extends StatefulWidget {
  final QrHistoryStore store;

  const HistoryScreen({super.key, this.store = const QrHistoryStore()});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<QrHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.store.load();
  }

  void _refresh() => setState(() => _future = widget.store.load());

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'This removes all saved QR records from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true) {
      await widget.store.clear();
      _refresh();
    }
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return '${local.year}-${p(local.month)}-${p(local.day)} '
        '${p(local.hour)}:${p(local.minute)}';
  }

  IconData _iconFor(QrContentType type) {
    switch (type) {
      case QrContentType.url:
        return Icons.link;
      case QrContentType.text:
        return Icons.notes;
      case QrContentType.email:
        return Icons.mail_outline;
      case QrContentType.phone:
        return Icons.phone;
      case QrContentType.sms:
        return Icons.sms;
      case QrContentType.whatsapp:
        return Icons.chat_bubble_outline;
      case QrContentType.wifi:
        return Icons.wifi;
      case QrContentType.vCard:
        return Icons.contact_page_outlined;
      case QrContentType.geoLocation:
        return Icons.place_outlined;
      case QrContentType.event:
        return Icons.event;
      case QrContentType.crypto:
        return Icons.currency_bitcoin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear history',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: FutureBuilder<List<QrHistoryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Semantics(
                label: 'Loading history',
                child: const CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load history.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final entries = snapshot.data ?? const <QrHistoryEntry>[];
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text('No saved codes yet.'),
                    const SizedBox(height: 4),
                    Text(
                      'Export a QR code and it will appear here.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, i) {
              final entry = entries[i];
              final subtitle =
                  '${entry.contentType.label} · ${_formatTimestamp(entry.createdAt)} · '
                  '${entry.resolution}px${entry.hasLogo ? ' · logo not stored' : ''}';
              return ListTile(
                leading: Icon(_iconFor(entry.contentType)),
                title: Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete entry',
                  onPressed: () async {
                    await widget.store.remove(entry.id);
                    _refresh();
                  },
                ),
                onTap: () => Navigator.of(context).pop(entry),
              );
            },
          );
        },
      ),
    );
  }
}
