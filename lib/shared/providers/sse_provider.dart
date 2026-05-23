import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyon/core/api/sse_service.dart';
import 'api_providers.dart';

class SseNotifier extends Notifier<void> {
  StreamSubscription<SseEvent>? _sub;

  @override
  void build() {
    _sub?.cancel();
    _sub = SseService.instance.events.listen(_onEvent);
    ref.onDispose(() => _sub?.cancel());
  }

  void _onEvent(SseEvent event) {
    switch (event.kind) {
      case SseEventKind.stateChanged:
        ref.invalidate(deviceStateProvider);
        ref.invalidate(eventsProvider);   // activity strip updates live
      case SseEventKind.commandConfirmed:
      case SseEventKind.commandFailed:
        ref.invalidate(commandsProvider);
        ref.invalidate(deviceStateProvider);
        ref.invalidate(eventsProvider);   // show command result immediately
      case SseEventKind.powerCut:
      case SseEventKind.powerRestored:
        ref.invalidate(deviceStateProvider);
        ref.invalidate(eventsProvider);
        ref.invalidate(reconciliationProvider);
      case SseEventKind.heartbeat:
      case SseEventKind.unknown:
        break;
    }
  }
}

final sseNotifierProvider = NotifierProvider<SseNotifier, void>(SseNotifier.new);