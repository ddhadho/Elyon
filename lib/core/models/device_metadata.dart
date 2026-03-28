import 'package:flutter/foundation.dart';

/// Device metadata from GET /devices.
/// Static — name, kind, writable. Never changes at runtime.
@immutable
class DeviceMetadata {
  final String id;
  final String name;
  final String kind;
  final bool   writable;

  const DeviceMetadata({
    required this.id,
    required this.name,
    required this.kind,
    required this.writable,
  });

  factory DeviceMetadata.fromJson(Map<String, dynamic> json) {
    return DeviceMetadata(
      id:       json['id']       as String,
      name:     json['name']     as String,
      kind:     json['kind']     as String,
      writable: json['writable'] as bool,
    );
  }

  /// Icon emoji for this device kind — matches API spec table
  String get icon => switch (kind) {
    'Gate'          => '🚪',
    'BoreholePump'  => '💧',
    'PowerMonitor'  => '⚡',
    'SecurityLight' => '💡',
    'WaterTank'     => '🪣',
    'AlarmPanel'    => '🔔',
    'Camera'        => '📷',
    'SmartPlug'     => '🔌',
    'Inverter'      => '🔋',
    'Generator'     => '⚙️',
    'Sensor'        => '📡',
    _               => '⚙️',
  };
}