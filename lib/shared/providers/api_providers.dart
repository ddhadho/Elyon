import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyon/core/api/api_client.dart';
import 'package:elyon/core/models/device_state.dart';
import 'package:elyon/core/models/device.dart';
import 'package:elyon/core/models/event_summary.dart';
import 'package:elyon/core/models/rule.dart';

// ── Devices + State ────────────────────────────────────────────────────────

final deviceStateProvider =
    FutureProvider.autoDispose<Map<String, DeviceState>>((ref) async {
  final json = await ApiClient.instance.getState();
  return DeviceState.mapFromJson(json);
});

final devicesProvider = FutureProvider.autoDispose<List<Device>>((ref) async {
  final json = await ApiClient.instance.getDevices();
  return Device.listFromJson(json);
});

// ── Commands ───────────────────────────────────────────────────────────────

final commandsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ApiClient.instance.getCommands();
});

// ── Events ─────────────────────────────────────────────────────────────────

final eventsProvider =
    FutureProvider.autoDispose<List<EventSummary>>((ref) async {
  final json = await ApiClient.instance.getEvents();
  return EventSummary.listFromJson(json);
});

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

      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        final cmds = await ApiClient.instance.getCommands();
        final matches = cmds
            .cast<Map<String, dynamic>>()
            .where((c) => c['id'] == commandId)
            .toList();

        if (matches.isEmpty) {
          state = AsyncValue.data(commandId);
          // ── Immediately refresh state + events so UI updates
          // without waiting for SSE (SSE will also fire, but this
          // ensures instant feedback if SSE is slightly delayed).
          ref.invalidate(deviceStateProvider);
          ref.invalidate(eventsProvider);
          return true;
        }

        final status = matches.first['status'] as String? ?? '';
        if (status == 'Failed') {
          state = AsyncValue.error('Command failed', StackTrace.current);
          ref.invalidate(eventsProvider); // show the failure in activity strip
          return false;
        }
      }

      state = AsyncValue.error('Command timed out after 15s', StackTrace.current);
      return false;
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final commandNotifierProvider =
    AsyncNotifierProvider<CommandNotifier, String?>(CommandNotifier.new);