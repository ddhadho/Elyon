import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarthome/core/api/api_client.dart';
import 'package:smarthome/core/models/device_state.dart';
import 'package:smarthome/core/models/device.dart';
import 'package:smarthome/core/models/event_summary.dart';
import 'package:smarthome/core/models/rule.dart';

// ── Devices + State ────────────────────────────────────────────────────────

/// All device states from GET /state. Auto-refreshes every 5 seconds
/// as fallback until SSE is fully wired.
final deviceStateProvider =
    FutureProvider.autoDispose<Map<String, DeviceState>>((ref) async {
  final json = await ApiClient.instance.getState();
  return DeviceState.mapFromJson(json);
});

/// Device metadata from GET /devices.
final devicesProvider = FutureProvider.autoDispose<List<Device>>((ref) async {
  final json = await ApiClient.instance.getDevices();
  return Device.listFromJson(json);
});

// ── Commands ───────────────────────────────────────────────────────────────

/// Pending + recent commands from GET /commands.
final commandsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiClient.instance.getCommands();
});

// ── Events ─────────────────────────────────────────────────────────────────

/// Event history from GET /events.
final eventsProvider =
    FutureProvider.autoDispose<List<EventSummary>>((ref) async {
  final json = await ApiClient.instance.getEvents();
  return EventSummary.listFromJson(json);
});

/// Events filtered by device — for device detail screen.
final deviceEventsProvider = FutureProvider.autoDispose
    .family<List<EventSummary>, String>((ref, deviceId) async {
  final json = await ApiClient.instance.getEvents(deviceId: deviceId);
  return EventSummary.listFromJson(json);
});

// ── Rules ──────────────────────────────────────────────────────────────────

class RulesState {
  final List<Rule> rules;
  final List<InFlightAction> inFlight;
  const RulesState({required this.rules, required this.inFlight});
}

final rulesProvider = FutureProvider.autoDispose<RulesState>((ref) async {
  final json = await ApiClient.instance.getRules();
  return RulesState(
    rules: Rule.listFromJson(json['rules'] as List? ?? []),
    inFlight: InFlightAction.listFromJson(json['in_flight'] as List? ?? []),
  );
});

// ── Reconciliation ─────────────────────────────────────────────────────────

final reconciliationProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ApiClient.instance.getReconciliation();
});

// ── HA entities ────────────────────────────────────────────────────────────

final haEntitiesProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiClient.instance.getHaEntities();
});

// ── Command posting ────────────────────────────────────────────────────────

/// Notifier for posting a command and polling for confirmation.
class CommandNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<bool> send({
    required String deviceId,
    required String attribute,
    required String value,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await ApiClient.instance.postCommand(
        deviceId: deviceId,
        attribute: attribute,
        value: value,
      );
      final commandId = res['command_id'] as String;

      // Poll GET /commands every 500ms until confirmed or failed (max 15s)
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final cmds = await ApiClient.instance.getCommands();
        final cmd = cmds.cast<Map<String, dynamic>>().where(
              (c) => c['id'] == commandId,
            );
        if (cmd.isEmpty) {
          // Removed from list = confirmed
          state = AsyncValue.data(commandId);
          return true;
        }
        if (cmd.first['status'] == 'Failed') {
          state = AsyncValue.error('Command failed', StackTrace.current);
          return false;
        }
      }
      state = AsyncValue.error('Command timed out', StackTrace.current);
      return false;
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final commandNotifierProvider =
    AsyncNotifierProvider<CommandNotifier, String?>(CommandNotifier.new);