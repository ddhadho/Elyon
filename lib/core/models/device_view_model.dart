import 'package:flutter/foundation.dart';
import 'device_metadata.dart';
import 'device_state.dart';

/// Joined view of a device — metadata + runtime state.
/// This is what every widget uses. Never read metadata or state separately in UI.
@immutable
class DeviceViewModel {
  final DeviceMetadata metadata;
  final DeviceState?   state; // null if daemon hasn't reported yet

  const DeviceViewModel({required this.metadata, this.state});

  String get id       => metadata.id;
  String get name     => metadata.name;
  String get kind     => metadata.kind;
  String get icon     => metadata.icon;
  bool   get writable => metadata.writable;

  /// The value to display — uses get_effective logic
  String effectiveState(String attr) =>
      state?.getEffective(attr) ?? '—';

  String get displayState => effectiveState('state');

  bool get isOn     => displayState == 'on';
  bool get isLocked => displayState == 'locked';
  bool get isActive => isOn || isLocked || displayState == 'kplc';

  bool   get isSafeDefaultActive => state?.isSafeDefaultActive ?? false;
  double get confidence          => state?.confidence.value ?? 0.0;
  int    get confidenceDots      => state?.confidence.dots ?? 0;
  DateTime? get lastSeen         => state?.lastSeen;

  String timeSinceLastSeen() {
    if (lastSeen == null) return 'never';
    final d = DateTime.now().difference(lastSeen!);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1)   return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}