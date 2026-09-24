import 'dart:convert';
import 'package:flutter/material.dart';
import 'qr_content_builder.dart';
import 'qr_style.dart';

/// Lightweight, reloadable record of a generated/exported QR code.
///
/// v1 scope (per plan): everything needed to revisit + reload without
/// retyping, while staying small enough for `shared_preferences`:
/// - [contentType], [label] (short human summary), [payload] (full encoded
///   string so preview/export work immediately),
/// - [createdAt], [resolution],
/// - [fields] controller snapshot + wifi/crypto/event selections so the
///   form restores editable (not just the payload),
/// - [styleJson] full [QrStyle] config **excluding** `logoBytes` (prefs
///   bloat) + [hasLogo] flag so UI can note the logo isn't restored.
class QrHistoryEntry {
  final String id;
  final QrContentType contentType;
  final String label;
  final String payload;
  final DateTime createdAt;
  final int resolution;
  final Map<String, String> fields;
  final String wifiEncryption;
  final String cryptoCurrency;
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final Map<String, dynamic> styleJson;
  final bool hasLogo;

  const QrHistoryEntry({
    required this.id,
    required this.contentType,
    required this.label,
    required this.payload,
    required this.createdAt,
    this.resolution = 1000,
    this.fields = const {},
    this.wifiEncryption = 'WPA',
    this.cryptoCurrency = 'bitcoin',
    this.eventStart,
    this.eventEnd,
    this.styleJson = const {},
    this.hasLogo = false,
  });

  /// Builds a short single-line summary from the payload (max 60 chars).
  static String labelFor(QrContentType type, String payload) {
    final singleLine = payload.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (singleLine.isEmpty) return type.label;
    const max = 60;
    final truncated = singleLine.length > max
        ? '${singleLine.substring(0, max - 1)}…'
        : singleLine;
    return '${type.label}: $truncated';
  }

  /// Captures current HomeScreen state. Does not read/write disk.
  factory QrHistoryEntry.fromCurrent({
    String? id,
    required QrContentType contentType,
    required String payload,
    required QrStyle style,
    required Map<String, String> fields,
    String wifiEncryption = 'WPA',
    String cryptoCurrency = 'bitcoin',
    DateTime? eventStart,
    DateTime? eventEnd,
    int resolution = 1000,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return QrHistoryEntry(
      id: id ?? '${now.microsecondsSinceEpoch}_${payload.hashCode & 0x7fffffff}',
      contentType: contentType,
      label: labelFor(contentType, payload),
      payload: payload,
      createdAt: now,
      resolution: resolution,
      fields: Map<String, String>.from(fields),
      wifiEncryption: wifiEncryption,
      cryptoCurrency: cryptoCurrency,
      eventStart: eventStart,
      eventEnd: eventEnd,
      styleJson: encodeQrStyle(style),
      hasLogo: style.logoBytes != null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': contentType.name,
        'label': label,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'resolution': resolution,
        'fields': fields,
        'wifi': wifiEncryption,
        'crypto': cryptoCurrency,
        'eventStart': eventStart?.toIso8601String(),
        'eventEnd': eventEnd?.toIso8601String(),
        'style': styleJson,
        'hasLogo': hasLogo,
        'v': 1,
      };

  factory QrHistoryEntry.fromJson(Map<String, dynamic> json) {
    QrContentType typeFrom(String? name) => QrContentType.values.firstWhere(
          (t) => t.name == name,
          orElse: () => QrContentType.text,
        );
    Map<String, String> stringMap(dynamic v) {
      if (v is Map) {
        return v.map((k, val) => MapEntry(k.toString(), val.toString()));
      }
      return const {};
    }

    DateTime? tryParseDate(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    final payload = (json['payload'] ?? '').toString();
    final type = typeFrom(json['type']?.toString());
    return QrHistoryEntry(
      id: (json['id'] ?? '').toString(),
      contentType: type,
      label: (json['label'] ?? '').toString().isNotEmpty
          ? json['label'].toString()
          : labelFor(type, payload),
      payload: payload,
      createdAt: tryParseDate(json['createdAt']) ?? DateTime.now(),
      resolution: (json['resolution'] is num)
          ? (json['resolution'] as num).toInt()
          : 1000,
      fields: stringMap(json['fields']),
      wifiEncryption: (json['wifi'] ?? 'WPA').toString(),
      cryptoCurrency: (json['crypto'] ?? 'bitcoin').toString(),
      eventStart: tryParseDate(json['eventStart']),
      eventEnd: tryParseDate(json['eventEnd']),
      styleJson: json['style'] is Map
          ? Map<String, dynamic>.from(json['style'] as Map)
          : const {},
      hasLogo: json['hasLogo'] == true,
    );
  }

  static String encodeList(List<QrHistoryEntry> entries) =>
      jsonEncode(entries.map((e) => e.toJson()).toList());

  static List<QrHistoryEntry> decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <QrHistoryEntry>[];
      final out = <QrHistoryEntry>[];
      for (final item in decoded) {
        try {
          if (item is Map) {
            out.add(QrHistoryEntry.fromJson(
                Map<String, dynamic>.from(item)));
          }
        } catch (_) {
          // Skip single corrupt entry, keep the rest.
        }
      }
      return out;
    } catch (_) {
      return <QrHistoryEntry>[];
    }
  }
}

// ---------------------------------------------------------------------------
// QrStyle JSON codec (new code — qr_style.dart itself untouched).
// Colors as ARGB int, enums by name, logoBytes excluded (see hasLogo).
// ---------------------------------------------------------------------------

Map<String, dynamic> encodeQrStyle(QrStyle s) => {
      'fg': s.foregroundColor.toARGB32(),
      'bg': s.backgroundColor.toARGB32(),
      'eyeFrame': s.eyeFrameColor.toARGB32(),
      'eyeBall': s.eyeBallColor.toARGB32(),
      'useCustomEye': s.useCustomEyeColor,
      'gradType': s.gradientType.name,
      'grad2': s.gradientColor2.toARGB32(),
      'gradAngle': s.gradientAngleDeg,
      'bgGrad': s.backgroundGradient,
      'bgGrad2': s.backgroundGradientColor2.toARGB32(),
      'body': s.bodyShape.name,
      'eyeFrameShape': s.eyeFrameShape.name,
      'eyeBallShape': s.eyeBallShape.name,
      'eyeStroke': s.eyeStrokeRatio,
      'eyeCorner': s.eyeCornerRatio,
      'logoSize': s.logoSizeRatio,
      'clearBg': s.removeBackgroundBehindLogo,
      'logoShape': s.logoShape.name,
      'logoBorderW': s.logoBorderWidth,
      'logoBorderColor': s.logoBorderColor.toARGB32(),
      'quiet': s.quietModules,
      'cornerR': s.cornerRadiusRatio,
      'ec': s.errorCorrectionLevel,
    };

/// Applies [json] onto [style] in place. Unknown/missing keys keep current
/// values (forward-compatible). Never touches `logoBytes`.
void applyQrStyleJson(QrStyle style, Map<String, dynamic> json) {
  Color colorOr(String key, Color fallback) {
    final v = json[key];
    if (v is num) return Color(v.toInt());
    return fallback;
  }

  T enumOr<T extends Enum>(String key, List<T> values, T fallback) {
    final name = json[key]?.toString();
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  double doubleOr(String key, double fallback) {
    final v = json[key];
    if (v is num) return v.toDouble();
    return fallback;
  }

  style
    ..foregroundColor = colorOr('fg', style.foregroundColor)
    ..backgroundColor = colorOr('bg', style.backgroundColor)
    ..eyeFrameColor = colorOr('eyeFrame', style.eyeFrameColor)
    ..eyeBallColor = colorOr('eyeBall', style.eyeBallColor)
    ..useCustomEyeColor = json['useCustomEye'] is bool
        ? json['useCustomEye'] as bool
        : style.useCustomEyeColor
    ..gradientType =
        enumOr('gradType', QrGradientType.values, style.gradientType)
    ..gradientColor2 = colorOr('grad2', style.gradientColor2)
    ..gradientAngleDeg = doubleOr('gradAngle', style.gradientAngleDeg)
    ..backgroundGradient = json['bgGrad'] is bool
        ? json['bgGrad'] as bool
        : style.backgroundGradient
    ..backgroundGradientColor2 =
        colorOr('bgGrad2', style.backgroundGradientColor2)
    ..bodyShape = enumOr('body', QrBodyShape.values, style.bodyShape)
    ..eyeFrameShape =
        enumOr('eyeFrameShape', QrEyeFrameShape.values, style.eyeFrameShape)
    ..eyeBallShape =
        enumOr('eyeBallShape', QrEyeBallShape.values, style.eyeBallShape)
    ..eyeStrokeRatio = doubleOr('eyeStroke', style.eyeStrokeRatio)
    ..eyeCornerRatio = doubleOr('eyeCorner', style.eyeCornerRatio)
    ..logoSizeRatio = doubleOr('logoSize', style.logoSizeRatio)
    ..removeBackgroundBehindLogo = json['clearBg'] is bool
        ? json['clearBg'] as bool
        : style.removeBackgroundBehindLogo
    ..logoShape = enumOr('logoShape', QrLogoShape.values, style.logoShape)
    ..logoBorderWidth = doubleOr('logoBorderW', style.logoBorderWidth)
    ..logoBorderColor = colorOr('logoBorderColor', style.logoBorderColor)
    ..quietModules = json['quiet'] is num
        ? (json['quiet'] as num).toInt()
        : style.quietModules
    ..cornerRadiusRatio = doubleOr('cornerR', style.cornerRadiusRatio)
    ..errorCorrectionLevel =
        (json['ec'] ?? style.errorCorrectionLevel).toString();
}
