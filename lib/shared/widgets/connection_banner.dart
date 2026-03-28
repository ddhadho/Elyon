import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daemon_providers.dart';

/// Shown at the top of every page when the daemon is unreachable.
/// Disappears automatically when connection is restored.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (status) {
        ConnectionStatus.disconnected => _Banner(
            key: const ValueKey('disconnected'),
            color: Theme.of(context).colorScheme.error,
            icon: Icons.wifi_off_rounded,
            message: 'Cannot reach daemon',
          ),
        ConnectionStatus.connecting => _Banner(
            key: const ValueKey('connecting'),
            color: Colors.orange,
            icon: Icons.sync_rounded,
            message: 'Connecting to daemon…',
          ),
        ConnectionStatus.connected => const SizedBox.shrink(
            key: ValueKey('connected'),
          ),
      },
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;

  const _Banner({
    super.key,
    required this.color,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color.withOpacity(0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }
}