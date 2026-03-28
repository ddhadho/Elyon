class EventSummary {
  final DateTime timestamp;
  final String kind;
  final String? deviceId;
  final String? attribute;
  final String? value;
  final String source;
  final String? commandId;

  const EventSummary({
    required this.timestamp,
    required this.kind,
    required this.source,
    this.deviceId,
    this.attribute,
    this.value,
    this.commandId,
  });

  /// Human-readable translation for the Activity screen.
  /// Never show raw kind strings to the tenant.
  String get humanReadable {
    if (kind == 'DeviceStateChanged' && deviceId == 'mains_power') {
      return value == 'outage' ? 'Power cut detected' : 'Power restored';
    }
    if (kind == 'CommandConfirmed') {
      final who = source.contains('Rule') ? 'automatic' : 'manual';
      final dev = deviceId ?? 'device';
      return '$dev → $value ($who)';
    }
    if (kind == 'CommandFailed') {
      return 'Command failed — ${deviceId ?? 'unknown device'}';
    }
    if (kind == 'RuleConflict') return 'Conflicting rules resolved';
    return kind;
  }

  /// Icon hint for the activity list tile
  String get icon {
    if (kind == 'DeviceStateChanged' && deviceId == 'mains_power') {
      return value == 'outage' ? '⚡' : '✅';
    }
    if (kind == 'CommandConfirmed') return '✓';
    if (kind == 'CommandFailed') return '✗';
    if (kind == 'RuleConflict') return '⚠';
    return '•';
  }

  factory EventSummary.fromJson(Map<String, dynamic> j) {
    return EventSummary(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (j['timestamp'] as num).toInt(),
      ),
      kind: j['kind'] as String,
      deviceId: j['device_id'] as String?,
      attribute: j['attribute'] as String?,
      value: j['value'] as String?,
      source: j['source'] as String? ?? '',
      commandId: j['command_id'] as String?,
    );
  }

  static List<EventSummary> listFromJson(List<dynamic> json) =>
      json.map((e) => EventSummary.fromJson(e as Map<String, dynamic>)).toList();
}