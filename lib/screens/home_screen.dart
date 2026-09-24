import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import '../models/qr_content_builder.dart';
import '../models/qr_history_entry.dart';
import '../models/qr_style.dart';
import '../utils/export_utils.dart';
import '../utils/logo_image.dart';
import '../utils/qr_history_store.dart';
import '../widgets/content_type_form.dart';
import '../widgets/design_panel.dart';
import '../widgets/qr_preview.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  QrContentType _type = QrContentType.url;
  final QrStyle _style = QrStyle();
  final GlobalKey<QrPreviewState> _previewKey = GlobalKey<QrPreviewState>();
  String _payload = '';
  int _resolution = 1000;

  // ----- form controllers (created lazily per field as needed) -----
  final Map<String, TextEditingController> _controllers = {};
  TextEditingController _c(String key) =>
      _controllers.putIfAbsent(key, () => TextEditingController());

  String _wifiEncryption = 'WPA';
  String _cryptoCurrency = 'bitcoin';
  DateTime _eventStart = DateTime.now();
  DateTime _eventEnd = DateTime.now().add(const Duration(hours: 1));

  final QrHistoryStore _historyStore = const QrHistoryStore();

  void _regenerate() {
    setState(() {
      switch (_type) {
        case QrContentType.url:
          _payload = QrContentBuilder.url(_c('url').text);
          break;
        case QrContentType.text:
          _payload = QrContentBuilder.text(_c('text').text);
          break;
        case QrContentType.email:
          _payload = QrContentBuilder.email(
            to: _c('email_to').text,
            subject: _c('email_subject').text,
            body: _c('email_body').text,
          );
          break;
        case QrContentType.phone:
          _payload = QrContentBuilder.phone(_c('phone').text);
          break;
        case QrContentType.sms:
          _payload = QrContentBuilder.sms(
            number: _c('sms_number').text,
            message: _c('sms_message').text,
          );
          break;
        case QrContentType.whatsapp:
          _payload = QrContentBuilder.whatsapp(
            number: _c('wa_number').text,
            message: _c('wa_message').text,
          );
          break;
        case QrContentType.wifi:
          _payload = QrContentBuilder.wifi(
            ssid: _c('wifi_ssid').text,
            password: _c('wifi_password').text,
            encryption: _wifiEncryption,
          );
          break;
        case QrContentType.vCard:
          _payload = QrContentBuilder.vCard(
            firstName: _c('v_first').text,
            lastName: _c('v_last').text,
            organization: _c('v_org').text,
            position: _c('v_position').text,
            phoneWork: _c('v_phone_work').text,
            phoneMobile: _c('v_phone_mobile').text,
            email: _c('v_email').text,
            website: _c('v_website').text,
            street: _c('v_street').text,
            city: _c('v_city').text,
            zip: _c('v_zip').text,
            country: _c('v_country').text,
          );
          break;
        case QrContentType.geoLocation:
          final lat = double.tryParse(_c('geo_lat').text) ?? 0;
          final lng = double.tryParse(_c('geo_lng').text) ?? 0;
          _payload = QrContentBuilder.geoLocation(lat: lat, lng: lng);
          break;
        case QrContentType.event:
          _payload = QrContentBuilder.event(
            title: _c('event_title').text,
            location: _c('event_location').text,
            start: _eventStart,
            end: _eventEnd,
          );
          break;
        case QrContentType.crypto:
          _payload = QrContentBuilder.crypto(
            currency: _cryptoCurrency,
            address: _c('crypto_address').text,
            amount: double.tryParse(_c('crypto_amount').text),
          );
          break;
      }
    });
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;
      final bytes = await img.readAsBytes();
      final normalized = await normalizeLogoBytes(bytes);
      if (!mounted) return;
      setState(() => _style.logoBytes = normalized);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add logo: $e')),
      );
    }
  }

  Future<void> _openHistory() async {
    final selected = await Navigator.of(context).push<QrHistoryEntry>(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(store: _historyStore),
      ),
    );
    if (selected == null || !mounted) return;
    _applyHistoryEntry(selected);
  }

  void _applyHistoryEntry(QrHistoryEntry entry) {
    setState(() {
      _type = entry.contentType;
      _wifiEncryption = entry.wifiEncryption;
      _cryptoCurrency = entry.cryptoCurrency;
      if (entry.eventStart != null) _eventStart = entry.eventStart!;
      if (entry.eventEnd != null) _eventEnd = entry.eventEnd!;
      _resolution = entry.resolution;
      for (final kv in entry.fields.entries) {
        _c(kv.key).text = kv.value;
      }
      applyQrStyleJson(_style, entry.styleJson);
    });
    // Recompute from restored fields so controllers stay source-of-truth.
    _regenerate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.history),
            const SizedBox(width: 12),
            Expanded(
              child: Text(entry.hasLogo
                  ? 'Loaded from history (logo image not stored).'
                  : 'Loaded from history.'),
            ),
          ],
        ),
      ),
    );
  }

  /// Best-effort history save. Called after successful generation;
  /// awaited so History opened right after export sees the entry.
  /// Failures are logged but never break export UX.
  Future<void> _recordHistory() async {
    if (_payload.isEmpty) {
      debugPrint('[history] skip: payload empty');
      return;
    }
    final fields = <String, String>{
      for (final e in _controllers.entries) e.key: e.value.text,
    };
    final entry = QrHistoryEntry.fromCurrent(
      contentType: _type,
      payload: _payload,
      style: _style,
      fields: fields,
      wifiEncryption: _wifiEncryption,
      cryptoCurrency: _cryptoCurrency,
      eventStart: _eventStart,
      eventEnd: _eventEnd,
      resolution: _resolution,
    );
    try {
      await _historyStore.save(entry);
      debugPrint('[history] saved ${entry.id} ${entry.label}');
    } catch (e) {
      debugPrint('[history] save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeAction = switch (widget.themeMode) {
      ThemeMode.light => (
          icon: Icons.light_mode,
          tooltip: 'Theme: Light (tap for Dark)',
          next: ThemeMode.dark,
        ),
      ThemeMode.dark => (
          icon: Icons.dark_mode,
          tooltip: 'Theme: Dark (tap for System)',
          next: ThemeMode.system,
        ),
      ThemeMode.system => (
          icon: Icons.brightness_auto,
          tooltip: 'Theme: System (tap for Light)',
          next: ThemeMode.light,
        ),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free QR Code Creator — Unlimited'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: _openHistory,
          ),
          IconButton(
            icon: Icon(themeAction.icon),
            tooltip: themeAction.tooltip,
            onPressed: () =>
                widget.onThemeModeChanged(themeAction.next),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Breakpoints: phone < 800, tablet 800–1199, desktop >= 1200.
          // Single LayoutBuilder covers all three; no MediaQuery needed
          // since the shell width (not the full window) drives the layout.
          final isDesktop = width >= 1200;
          final isWide = width >= 800;
          final formPanel = _buildFormPanel();

          if (!isWide) {
            // Phone: single scroll, content form → design panel → preview.
            final previewSize = (width - 96).clamp(200.0, 300.0);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  formPanel,
                  _buildPreviewPanel(displaySize: previewSize),
                ],
              ),
            );
          }

          // Tablet/desktop: two-pane. Left scrolls independently; right
          // preview stays pinned in its own column so edits are visible
          // without scrolling. Desktop gets a wider preview + centered
          // max-width shell; tablet uses flex proportions.
          final previewSize = isDesktop ? 340.0 : 300.0;
          final previewPanel =
              _buildPreviewPanel(displaySize: previewSize);
          final formScroll = SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 720 : 640,
                ),
                child: formPanel,
              ),
            ),
          );
          final previewScroll = SingleChildScrollView(child: previewPanel);

          if (isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: formScroll),
                    const VerticalDivider(width: 1),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: previewScroll,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: formScroll),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: previewScroll,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPreviewPanel({double displaySize = 280}) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrPreview(
              key: _previewKey,
              data: _payload,
              style: _style,
              displaySize: displaySize,
            ),
          ),
          const SizedBox(height: 16),
          MergeSemantics(
            child: Column(
              children: [
                Text('Export resolution: $_resolution px'),
                Slider(
                  min: 300,
                  max: 4000,
                  divisions: 37,
                  value: _resolution.toDouble(),
                  label: '$_resolution px',
                  semanticFormatterCallback: (v) =>
                      '${v.round()} pixels',
                  onChanged: (v) =>
                      setState(() => _resolution = v.round()),
                ),
              ],
            ),
          ),
          Text('No size cap, no watermark, no ads — export as large as you need.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _payload.isEmpty ? null : _exportPng,
                icon: const Icon(Icons.image),
                label: const Text('PNG'),
              ),
              ElevatedButton.icon(
                onPressed: _payload.isEmpty ? null : _exportSvg,
                icon: const Icon(Icons.polyline),
                label: const Text('SVG (vector)'),
              ),
              ElevatedButton.icon(
                onPressed: _payload.isEmpty ? null : _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExportError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(_friendlyExportError(e))),
          ],
        ),
      ),
    );
  }

  String _friendlyExportError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('permission') ||
        raw.contains('denied') ||
        raw.contains('not allowed') ||
        raw.contains('not granted')) {
      return 'Export failed: permission denied. Please allow file/share access and try again.';
    }
    if (raw.contains('enospc') ||
        raw.contains('no space') ||
        raw.contains('disk full') ||
        raw.contains('storage')) {
      return 'Export failed: not enough storage space. Free up space and try again.';
    }
    return 'Export failed: $e';
  }

  void _showExportSuccess(String kind) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: 12),
            Expanded(child: Text('$kind saved — check share sheet or downloads.')),
          ],
        ),
      ),
    );
  }

  /// Shows a labeled modal progress indicator while [work] runs, then
  /// dismisses it before the exception (if any) propagates to the caller.
  /// Generation only — the share sheet / browser download is not covered.
  Future<T?> _withProgress<T>(Future<T> Function() work,
      {required String message}) async {
    BuildContext? dialogCtx;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogCtx = ctx;
        return AlertDialog(
          content: Semantics(
            liveRegion: true,
            label: message,
            child: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
    // Let the dialog transition fade in so the indicator is visible before
    // heavy (potentially frame-blocking) work starts.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    try {
      return await work();
    } finally {
      final ctx = dialogCtx;
      if (ctx != null && ctx.mounted) Navigator.of(ctx).pop();
    }
  }

  Future<void> _exportPng() async {
    try {
      final bytes = await _withProgress(
        () => _previewKey.currentState!.captureAsPng(_resolution),
        message: 'Generating PNG at $_resolution px…',
      );
      if (bytes == null) return;
      // Record on generation success so a later share failure can't
      // swallow history. Awaited so History sees it immediately.
      await _recordHistory();
      await ExportUtils.savePngAndShare(bytes);
      _showExportSuccess('PNG');
    } catch (e) {
      _showExportError(e);
    }
  }

  Future<void> _exportSvg() async {
    try {
      final svg = ExportUtils.buildSvg(_payload, _style, size: _resolution);
      await _recordHistory();
      await ExportUtils.saveSvgAndShare(svg);
      _showExportSuccess('SVG');
    } catch (e) {
      _showExportError(e);
    }
  }

  Future<void> _exportPdf() async {
    try {
      final pdfBytes = await _withProgress(() async {
        // Cap the page raster at 2048px: the image is placed at 400pt
        // (~5.6in) on A4, so 2048px is ~370 DPI (print-perfect) while
        // 4000px quadruples PNG-encode time and froze the web build.
        final png = await _previewKey.currentState!
            .captureAsPng(_resolution > 2048 ? 2048 : _resolution);
        // Yield a frame so the spinner animates between heavy steps.
        await SchedulerBinding.instance.endOfFrame;
        return ExportUtils.buildPdf(png);
      }, message: 'Building PDF…');
      if (pdfBytes == null) return;
      await _recordHistory();
      await ExportUtils.deliverPdf(pdfBytes);
      _showExportSuccess('PDF');
    } catch (e) {
      _showExportError(e);
    }
  }

  Widget _buildFormPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. Content', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ContentTypeForm(
            contentType: _type,
            onContentTypeChanged: (t) => setState(() => _type = t),
            controllerFor: _c,
            onChanged: _regenerate,
            wifiEncryption: _wifiEncryption,
            onWifiEncryptionChanged: (v) {
              setState(() => _wifiEncryption = v);
              _regenerate();
            },
            cryptoCurrency: _cryptoCurrency,
            onCryptoCurrencyChanged: (v) {
              setState(() => _cryptoCurrency = v);
              _regenerate();
            },
            eventStart: _eventStart,
            eventEnd: _eventEnd,
            onEventStartChanged: (d) {
              setState(() => _eventStart = d);
              _regenerate();
            },
            onEventEndChanged: (d) {
              setState(() => _eventEnd = d);
              _regenerate();
            },
          ),
          const SizedBox(height: 24),
          const Text('2. Design', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          _buildDesignPanel(),
        ],
      ),
    );
  }

  Widget _buildDesignPanel() {
    // Thin wrapper — all controls live in DesignPanel; state + values
    // unchanged, only grouped/themed.
    return DesignPanel(
      style: _style,
      onChanged: () => setState(() {}),
      onPickLogo: _pickLogo,
    );
  }
}
