import 'package:flutter/foundation.dart';

/// Device metadata from GET /devices.
/// Static — name, kind, writable. Never changes at runtime.
@immutable
class Device {
  final String id;
  final String name;
  final String kind;
  final bool   writable;

  const Device({
    required this.id,
    required this.name,
    required this.kind,
    required this.writable,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id:       json['id']       as String,
      name:     json['name']     as String,
      kind:     json['kind']     as String,
      writable: json['writable'] as bool,
    );
  }

  static List<Device> listFromJson(List<dynamic> json) {
    return json
        .cast<Map<String, dynamic>>()
        .map(Device.fromJson)
        .toList();
  }

  /// Icon emoji — matches API spec table
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

  /// Human-readable kind label
  String get label => switch (kind) {
    'Gate'          => 'Gate',
    'BoreholePump'  => 'Borehole Pump',
    'PowerMonitor'  => 'Power Monitor',
    'SecurityLight' => 'Security Light',
    'WaterTank'     => 'Water Tank',
    'AlarmPanel'    => 'Alarm Panel',
    'Camera'        => 'Camera',
    'SmartPlug'     => 'Smart Plug',
    'Inverter'      => 'Inverter',
    'Generator'     => 'Generator',
    'Sensor'        => 'Sensor',
    _               => 'Device',
  };
}