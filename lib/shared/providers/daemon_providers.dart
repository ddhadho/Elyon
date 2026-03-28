import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_providers.dart';

// ── Connection status ──────────────────────────────────────────
// Derived from deviceStateProvider — if it errors we're disconnected.

enum ConnectionStatus { connecting, connected, disconnected }

final connectionStatusProvider = Provider<ConnectionStatus>((ref) {
  final state = ref.watch(deviceStateProvider);
  return state.when(
    data:    (_)    => ConnectionStatus.connected,
    loading: ()     => ConnectionStatus.connecting,
    error:   (_, __) => ConnectionStatus.disconnected,
  );
});