/// All supported QR content types (mirrors and extends the classic
/// QRCode-Monkey style generator: URL, Text, Email, Phone, SMS, WiFi,
/// vCard, Geo Location, Calendar Event, Bitcoin / crypto payment).
enum QrContentType {
  url,
  text,
  email,
  phone,
  sms,
  whatsapp,
  wifi,
  vCard,
  geoLocation,
  event,
  crypto,
}

extension QrContentTypeLabel on QrContentType {
  String get label {
    switch (this) {
      case QrContentType.url:
        return 'URL';
      case QrContentType.text:
        return 'Text';
      case QrContentType.email:
        return 'Email';
      case QrContentType.phone:
        return 'Phone';
      case QrContentType.sms:
        return 'SMS';
      case QrContentType.whatsapp:
        return 'WhatsApp';
      case QrContentType.wifi:
        return 'WiFi';
      case QrContentType.vCard:
        return 'vCard';
      case QrContentType.geoLocation:
        return 'Location';
      case QrContentType.event:
        return 'Event';
      case QrContentType.crypto:
        return 'Crypto';
    }
  }
}

/// Turns user-entered form fields into the correctly-formatted string that
/// gets encoded into the QR code (following the standard URI schemes that
/// phones/scanners already understand).
class QrContentBuilder {
  static String url(String value) {
    var v = value.trim();
    if (v.isEmpty) return '';
    if (!v.startsWith('http://') && !v.startsWith('https://')) {
      v = 'https://$v';
    }
    return v;
  }

  static String text(String value) => value;

  static String email({
    required String to,
    String subject = '',
    String body = '',
  }) {
    final params = <String>[];
    if (subject.isNotEmpty) params.add('subject=${Uri.encodeComponent(subject)}');
    if (body.isNotEmpty) params.add('body=${Uri.encodeComponent(body)}');
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    return 'mailto:$to$query';
  }

  static String phone(String number) => 'tel:${number.trim()}';

  static String sms({required String number, String message = ''}) {
    if (message.isEmpty) return 'sms:$number';
    return 'sms:$number?body=${Uri.encodeComponent(message)}';
  }

  static String whatsapp({required String number, String message = ''}) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    final text = message.isEmpty ? '' : '?text=${Uri.encodeComponent(message)}';
    return 'https://wa.me/$digits$text';
  }

  /// encryption: 'nopass' | 'WEP' | 'WPA'
  static String wifi({
    required String ssid,
    required String password,
    String encryption = 'WPA',
    bool hidden = false,
  }) {
    String esc(String s) => s
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll(':', '\\:')
        .replaceAll('"', '\\"');
    final type = encryption == 'nopass' ? 'nopass' : encryption;
    return 'WIFI:T:$type;S:${esc(ssid)};P:${esc(password)};H:${hidden ? 'true' : 'false'};;';
  }

  static String vCard({
    String firstName = '',
    String lastName = '',
    String organization = '',
    String position = '',
    String phoneWork = '',
    String phonePrivate = '',
    String phoneMobile = '',
    String email = '',
    String website = '',
    String street = '',
    String zip = '',
    String city = '',
    String state = '',
    String country = '',
  }) {
    final b = StringBuffer();
    b.writeln('BEGIN:VCARD');
    b.writeln('VERSION:3.0');
    b.writeln('N:$lastName;$firstName;;;');
    b.writeln('FN:$firstName $lastName'.trim());
    if (organization.isNotEmpty) b.writeln('ORG:$organization');
    if (position.isNotEmpty) b.writeln('TITLE:$position');
    if (phoneWork.isNotEmpty) b.writeln('TEL;TYPE=WORK,VOICE:$phoneWork');
    if (phonePrivate.isNotEmpty) b.writeln('TEL;TYPE=HOME,VOICE:$phonePrivate');
    if (phoneMobile.isNotEmpty) b.writeln('TEL;TYPE=CELL:$phoneMobile');
    if (email.isNotEmpty) b.writeln('EMAIL:$email');
    if (website.isNotEmpty) b.writeln('URL:$website');
    if ([street, zip, city, state, country].any((e) => e.isNotEmpty)) {
      b.writeln('ADR;TYPE=WORK:;;$street;$city;$state;$zip;$country');
    }
    b.writeln('END:VCARD');
    return b.toString();
  }

  static String geoLocation({required double lat, required double lng}) =>
      'geo:$lat,$lng';

  /// start/end as DateTime; formatted to iCalendar UTC basic format.
  static String event({
    required String title,
    String location = '',
    required DateTime start,
    required DateTime end,
  }) {
    String fmt(DateTime d) {
      final u = d.toUtc();
      String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
      return '${u.year}${p(u.month)}${p(u.day)}T${p(u.hour)}${p(u.minute)}${p(u.second)}Z';
    }

    final b = StringBuffer();
    b.writeln('BEGIN:VEVENT');
    b.writeln('SUMMARY:$title');
    if (location.isNotEmpty) b.writeln('LOCATION:$location');
    b.writeln('DTSTART:${fmt(start)}');
    b.writeln('DTEND:${fmt(end)}');
    b.writeln('END:VEVENT');
    return b.toString();
  }

  /// currency: 'bitcoin' | 'litecoin' | 'ethereum' | 'dash' | 'bitcoincash'
  static String crypto({
    required String currency,
    required String address,
    double? amount,
  }) {
    final scheme = switch (currency) {
      'litecoin' => 'litecoin',
      'ethereum' => 'ethereum',
      'dash' => 'dash',
      'bitcoincash' => 'bitcoincash',
      _ => 'bitcoin',
    };
    final amt = amount != null && amount > 0 ? '?amount=$amount' : '';
    return '$scheme:$address$amt';
  }
}
