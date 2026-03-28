import 'package:flutter/foundation.dart';

const double _unknownThreshold = 0.2;

/// Runtime state from GET /state for a single device.
@immutable
class DeviceState {
  final String              deviceId;
  final Map<String, dynamic> actual;
  final Map<String, dynamic> desired;
  final Map<String, dynamic> previous;
  final Confidence           confidence;
  final DateTime             lastSeen;

  const DeviceState({
    required this.deviceId,
    required this.actual,
    required this.desired,
    required this.previous,
    required this.confidence,
    required this.lastSeen,
  });

  /// Mirrors Rust get_effective() — use this for display, never read actual directly.
  String getEffective(String attr) {
    if (confidence.value <= _unknownThreshold) {
      final sd = confidence.safeDefault[attr];
      if (sd != null) return sd.toString();
    }
    return actual[attr]?.toString() ?? '—';
  }

  bool get isSafeDefaultActive => confidence.value <= _unknownThreshold;

  factory DeviceState.fromJson(String id, Map<String, dynamic> json) {
    return DeviceState(
      deviceId:   id,
      actual:     _toStringMap(json['actual']),
      desired:    _toStringMap(json['desired']),
      previous:   _toStringMap(json['previous']),
      confidence: Confidence.fromJson(json['confidence'] as Map<String, dynamic>? ?? {}),
      lastSeen:   _parseTimestamp(json['last_seen']),
    );
  }

  static Map<String, dynamic> _toStringMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  static DateTime _parseTimestamp(dynamic raw) {
    if (raw is Map) {
      final secs = (raw['secs_since_epoch'] as num?)?.toInt() ?? 0;
      return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Parse the full /state response map
  static Map<String, DeviceState> mapFromJson(Map<String, dynamic> json) {
    return json.map((id, value) =>
        MapEntry(id, DeviceState.fromJson(id, value as Map<String, dynamic>)));
  }
}

@immutable
class Confidence {
  final double             value;
  final Duration           decaysAfter;
  final Map<String, dynamic> safeDefault;

  const Confidence({
    required this.value,
    required this.decaysAfter,
    required this.safeDefault,
  });

  /// 0–5 filled dots. Each dot = 20%.
  int get dots => (value * 5).round().clamp(0, 5);

  factory Confidence.fromJson(Map<String, dynamic> json) {
    final decays = json['decays_after'] as Map<String, dynamic>? ?? {};
    return Confidence(
      value:       (json['value'] as num?)?.toDouble() ?? 0.0,
      decaysAfter: Duration(seconds: (decays['secs'] as num?)?.toInt() ?? 0),
      safeDefault: Map<String, dynamic>.from(json['safe_default'] as Map? ?? {}),
    );
  }
}