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
  /// Source format from daemon: "device:main_gate", "Rule(rule_001)", "User"
  String get humanReadable {
    final dev = deviceId ?? 'device';
    final val = value ?? '';

    if (kind == 'DeviceStateChanged') {
      if (deviceId == 'mains_power') {
        return val == 'outage' ? 'Power cut detected' : 'Power restored';
      }
      final who = _sourceLabel;
      return '$dev → $val · $who';
    }

    if (kind == 'CommandConfirmed') {
      return '$dev → $val · ${_sourceLabel}';
    }

    if (kind == 'CommandFailed') {
      return 'Command failed — $dev';
    }

    if (kind == 'RuleConflict') return 'Conflicting rules resolved';

    return kind;
  }

  /// Translates raw source string to a readable label.
  /// "device:main_gate" → "device"
  /// "Rule(rule_001)"   → "automatic"
  /// "User"             → "manual"
  String get _sourceLabel {
    if (source.startsWith('Rule')) return 'automatic';
    if (source == 'User') return 'manual';
    if (source.startsWith('device:')) return 'device';
    return source;
  }

  String get icon {
    if (kind == 'DeviceStateChanged' && deviceId == 'mains_power') {
      return value == 'outage' ? '⚡' : '✅';
    }
    if (kind == 'CommandConfirmed') return '✓';
    if (kind == 'CommandFailed')    return '✗';
    if (kind == 'RuleConflict')     return '⚠';
    if (value == 'locked' || value == 'on')     return '🔒';
    if (value == 'unlocked' || value == 'off')  return '🔓';
    return '•';
  }

  factory EventSummary.fromJson(Map<String, dynamic> j) {
    return EventSummary(
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (j['timestamp'] as num).toInt(),
      ),
      kind:      j['kind']      as String,
      deviceId:  j['device_id'] as String?,
      attribute: j['attribute'] as String?,
      value:     j['value']     as String?,
      source:    j['source']    as String? ?? '',
      commandId: j['command_id'] as String?,
    );
  }

  static List<EventSummary> listFromJson(List<dynamic> json) =>
      json.map((e) => EventSummary.fromJson(e as Map<String, dynamic>)).toList();
}