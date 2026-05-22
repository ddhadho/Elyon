import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyon/core/api/sse_service.dart';
import 'api_providers.dart';

/// Subscribes to the SSE stream and invalidates the relevant providers
/// when the daemon pushes an update. Mount this once at the top of the
/// widget tree via [SseListener].
class SseNotifier extends Notifier<void> {
  StreamSubscription<SseEvent>? _sub;

  @override
  void build() {
    _sub?.cancel();
    _sub = SseService.instance.events.listen(_onEvent);

    // Clean up when the provider is disposed
    ref.onDispose(() => _sub?.cancel());
  }

  void _onEvent(SseEvent event) {
    switch (event.kind) {
      case SseEventKind.stateChanged:
        // A device state changed — refresh home screen data
        ref.invalidate(deviceStateProvider);

      case SseEventKind.commandConfirmed:
      case SseEventKind.commandFailed:
        // Command resolved — refresh commands + state
        ref.invalidate(commandsProvider);
        ref.invalidate(deviceStateProvider);

      case SseEventKind.powerCut:
      case SseEventKind.powerRestored:
        // Power event — refresh everything
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