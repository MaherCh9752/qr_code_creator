import 'package:flutter/material.dart';
import '../models/qr_content_builder.dart';

/// Content section of the home screen (type picker + per-type form fields).
///
/// Pure UI: owns no state. [HomeScreen] owns the controllers, the selected
/// type, wifi/crypto selections and event dates, and passes them in with
/// callbacks. Every interaction maps 1:1 to the old `_buildContentForm`
/// / `_field` code in `home_screen.dart` — same fields, same keys, same
/// `_regenerate` call sites.
class ContentTypeForm extends StatelessWidget {
  final QrContentType contentType;
  final ValueChanged<QrContentType> onContentTypeChanged;
  final TextEditingController Function(String key) controllerFor;
  final VoidCallback onChanged;

  final String wifiEncryption;
  final ValueChanged<String> onWifiEncryptionChanged;

  final String cryptoCurrency;
  final ValueChanged<String> onCryptoCurrencyChanged;

  final DateTime eventStart;
  final DateTime eventEnd;
  final ValueChanged<DateTime> onEventStartChanged;
  final ValueChanged<DateTime> onEventEndChanged;

  const ContentTypeForm({
    super.key,
    required this.contentType,
    required this.onContentTypeChanged,
    required this.controllerFor,
    required this.onChanged,
    required this.wifiEncryption,
    required this.onWifiEncryptionChanged,
    required this.cryptoCurrency,
    required this.onCryptoCurrencyChanged,
    required this.eventStart,
    required this.eventEnd,
    required this.onEventStartChanged,
    required this.onEventEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<QrContentType>(
          value: contentType,
          isExpanded: true,
          items: QrContentType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (t) {
            if (t != null) onContentTypeChanged(t);
          },
        ),
        const SizedBox(height: 8),
        _buildContentForm(context),
      ],
    );
  }

  Widget _field(String key, String label,
      {bool multiline = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controllerFor(key),
        maxLines: multiline ? 3 : 1,
        keyboardType: keyboard,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true),
        onChanged: (_) => onChanged(),
      ),
    );
  }

  Widget _buildContentForm(BuildContext context) {
    switch (contentType) {
      case QrContentType.url:
        return _field('url', 'Website URL', keyboard: TextInputType.url);
      case QrContentType.text:
        return _field('text', 'Text', multiline: true);
      case QrContentType.email:
        return Column(children: [
          _field('email_to', 'Email address',
              keyboard: TextInputType.emailAddress),
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
          _field('wa_number', 'Phone number (with country code)',
              keyboard: TextInputType.phone),
          _field('wa_message', 'Pre-filled message', multiline: true),
        ]);
      case QrContentType.wifi:
        return Column(children: [
          _field('wifi_ssid', 'Network name (SSID)'),
          _field('wifi_password', 'Password'),
          DropdownButton<String>(
            value: wifiEncryption,
            items: const [
              DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
              DropdownMenuItem(value: 'WEP', child: Text('WEP')),
              DropdownMenuItem(value: 'nopass', child: Text('No encryption')),
            ],
            onChanged: (v) {
              if (v != null) onWifiEncryptionChanged(v);
            },
          ),
        ]);
      case QrContentType.vCard:
        return Column(children: [
          _field('v_first', 'First name'),
          _field('v_last', 'Last name'),
          _field('v_org', 'Organization'),
          _field('v_position', 'Position'),
          _field('v_phone_work', 'Phone (work)',
              keyboard: TextInputType.phone),
          _field('v_phone_mobile', 'Phone (mobile)',
              keyboard: TextInputType.phone),
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
            title: Text('Start: $eventStart'),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: eventStart,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                onEventStartChanged(picked);
              } else {
                // Preserve original: _regenerate() ran even on cancel.
                onChanged();
              }
            },
          ),
          ListTile(
            title: Text('End: $eventEnd'),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: eventEnd,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                onEventEndChanged(picked);
              } else {
                onChanged();
              }
            },
          ),
        ]);
      case QrContentType.crypto:
        return Column(children: [
          DropdownButton<String>(
            value: cryptoCurrency,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'bitcoin', child: Text('Bitcoin')),
              DropdownMenuItem(
                  value: 'bitcoincash', child: Text('Bitcoin Cash')),
              DropdownMenuItem(value: 'ethereum', child: Text('Ethereum')),
              DropdownMenuItem(value: 'litecoin', child: Text('Litecoin')),
              DropdownMenuItem(value: 'dash', child: Text('Dash')),
            ],
            onChanged: (v) {
              if (v != null) onCryptoCurrencyChanged(v);
            },
          ),
          _field('crypto_address', 'Wallet address'),
          _field('crypto_amount', 'Amount (optional)',
              keyboard: TextInputType.number),
        ]);
    }
  }
}
