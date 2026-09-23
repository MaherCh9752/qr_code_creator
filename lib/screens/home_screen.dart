import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import '../models/qr_content_builder.dart';
import '../models/qr_style.dart';
import '../utils/export_utils.dart';
import '../utils/logo_image.dart';
import '../widgets/design_panel.dart';
import '../widgets/qr_preview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Free QR Code Creator — Unlimited')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 900;
          final formPanel = _buildFormPanel();
          final previewPanel = _buildPreviewPanel();
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(child: formPanel),
                ),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(child: previewPanel),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(children: [previewPanel, formPanel]),
          );
        },
      ),
    );
  }

  Widget _buildPreviewPanel() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrPreview(
              key: _previewKey,
              data: _payload,
              style: _style,
              displaySize: 280,
            ),
          ),
          const SizedBox(height: 16),
          Text('Export resolution: $_resolution px'),
          Slider(
            min: 300,
            max: 4000,
            divisions: 37,
            value: _resolution.toDouble(),
            label: '$_resolution px',
            onChanged: (v) => setState(() => _resolution = v.round()),
          ),
          const Text('No size cap, no watermark, no ads — export as large as you need.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
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
      SnackBar(content: Text('Export failed: $e')),
    );
  }

  /// Shows a modal progress spinner while [work] runs, then dismisses it
  /// before the exception (if any) propagates to the caller.
  Future<T?> _withProgress<T>(Future<T> Function() work) async {
    BuildContext? dialogCtx;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogCtx = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );
    // Let the dialog transition fade in so the spinner is visible before
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
          () => _previewKey.currentState!.captureAsPng(_resolution));
      if (bytes == null) return;
      await ExportUtils.savePngAndShare(bytes);
    } catch (e) {
      _showExportError(e);
    }
  }

  Future<void> _exportSvg() async {
    try {
      final svg = ExportUtils.buildSvg(_payload, _style, size: _resolution);
      await ExportUtils.saveSvgAndShare(svg);
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
      });
      if (pdfBytes == null) return;
      await ExportUtils.deliverPdf(pdfBytes);
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
          DropdownButton<QrContentType>(
            value: _type,
            isExpanded: true,
            items: QrContentType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (t) => setState(() => _type = t!),
          ),
          const SizedBox(height: 8),
          _buildContentForm(),
          const SizedBox(height: 24),
          const Text('2. Design', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          _buildDesignPanel(),
        ],
      ),
    );
  }

  Widget _field(String key, String label, {bool multiline = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: _c(key),
        maxLines: multiline ? 3 : 1,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
        onChanged: (_) => _regenerate(),
      ),
    );
  }

  Widget _buildContentForm() {
    switch (_type) {
      case QrContentType.url:
        return _field('url', 'Website URL', keyboard: TextInputType.url);
      case QrContentType.text:
        return _field('text', 'Text', multiline: true);
      case QrContentType.email:
        return Column(children: [
          _field('email_to', 'Email address', keyboard: TextInputType.emailAddress),
          _field('email_subject', 'Subject'),
          _field('email_body', 'Message', multiline: true),
        ]);
      case QrContentType.phone:
        return _field('phone', 'Phone number', keyboard: TextInputType.phone);
      case QrContentType.sms:
        return Column(children: [
          _field('sms_number', 'Phone number', keyboard: TextInputType.phone),
          _field('sms_message', 'Message', multiline: true),
        ]);
      case QrContentType.whatsapp:
        return Column(children: [
          _field('wa_number', 'Phone number (with country code)', keyboard: TextInputType.phone),
          _field('wa_message', 'Pre-filled message', multiline: true),
        ]);
      case QrContentType.wifi:
        return Column(children: [
          _field('wifi_ssid', 'Network name (SSID)'),
          _field('wifi_password', 'Password'),
          DropdownButton<String>(
            value: _wifiEncryption,
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('No encryption')),
            ],
            onChanged: (v) {
              setState(() => _wifiEncryption = v!);
              _regenerate();
            },
          ),
        ]);
      case QrContentType.vCard:
        return Column(children: [
          _field('v_first', 'First name'),
          _field('v_last', 'Last name'),
          _field('v_org', 'Organization'),
          _field('v_position', 'Position'),
          _field('v_phone_work', 'Phone (work)', keyboard: TextInputType.phone),
          _field('v_phone_mobile', 'Phone (mobile)', keyboard: TextInputType.phone),
          _field('v_email', 'Email', keyboard: TextInputType.emailAddress),
          _field('v_website', 'Website'),
          _field('v_street', 'Street'),
          _field('v_city', 'City'),
          _field('v_zip', 'Zip code'),
          _field('v_country', 'Country'),
        ]);
      case QrContentType.geoLocation:
        return Column(children: [
          _field('geo_lat', 'Latitude', keyboard: TextInputType.number),
          _field('geo_lng', 'Longitude', keyboard: TextInputType.number),
        ]);
      case QrContentType.event:
        return Column(children: [
          _field('event_title', 'Event title'),
          _field('event_location', 'Location'),
          ListTile(
            title: Text('Start: $_eventStart'),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _eventStart,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _eventStart = picked);
              _regenerate();
            },
          ),
          ListTile(
            title: Text('End: $_eventEnd'),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _eventEnd,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _eventEnd = picked);
              _regenerate();
            },
          ),
        ]);
      case QrContentType.crypto:
        return Column(children: [
          DropdownButton<String>(
            value: _cryptoCurrency,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'bitcoin', child: Text('Bitcoin')),
              DropdownMenuItem(value: 'bitcoincash', child: Text('Bitcoin Cash')),
              DropdownMenuItem(value: 'ethereum', child: Text('Ethereum')),
              DropdownMenuItem(value: 'litecoin', child: Text('Litecoin')),
              DropdownMenuItem(value: 'dash', child: Text('Dash')),
            ],
            onChanged: (v) {
              setState(() => _cryptoCurrency = v!);
              _regenerate();
            },
          ),
          _field('crypto_address', 'Wallet address'),
          _field('crypto_amount', 'Amount (optional)', keyboard: TextInputType.number),
        ]);
    }
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
