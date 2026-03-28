import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarthome/core/models/device.dart';
import 'package:smarthome/core/models/device_state.dart';
import 'package:smarthome/shared/providers/api_providers.dart';
import 'package:smarthome/shared/theme/app_theme.dart';

class DeviceCard extends ConsumerWidget {
  final Device      device;
  final DeviceState? state; // null if daemon hasn't reported yet

  const DeviceCard({super.key, required this.device, this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveValue = state?.getEffective('state') ?? '—';
    final isSafeDefault  = state?.isSafeDefaultActive ?? false;
    final isActive       = effectiveValue == 'on' ||
                           effectiveValue == 'locked' ||
                           effectiveValue == 'kplc';

    return GestureDetector(
      onTap: () => _showDetailSheet(context, ref, effectiveValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.orange.withOpacity(0.5)
                : const Color(0xFF2A3A5C),
          ),
          color: isActive
              ? AppColors.orange.withOpacity(0.07)
              : AppColors.surface,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + confidence dot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IconChip(icon: device.icon, active: isActive),
                const Spacer(),
                if (state != null)
                  _ConfidenceDot(value: state!.confidence.value),
              ],
            ),
            const Spacer(),
            // Name
            Text(
              device.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // State
            Text(
              effectiveValue.toUpperCase(),
              style: TextStyle(
                color: isActive ? AppColors.orange : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            // Safe default warning
            if (isSafeDefault) ...[
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 10, color: AppColors.red),
                  SizedBox(width: 3),
                  Text('Safe default',
                      style: TextStyle(color: AppColors.red, fontSize: 9)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, String currentValue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(
        device: device,
        state: state,
        currentValue: currentValue,
        ref: ref,
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final Device      device;
  final DeviceState? state;
  final String      currentValue;
  final WidgetRef   ref;

  const _DetailSheet({
    required this.device,
    required this.state,
    required this.currentValue,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final commandAsync = ref.watch(commandNotifierProvider);
    final isLoading    = commandAsync.isLoading;

    final nextValue = switch (currentValue) {
      'on'       => 'off',
      'off'      => 'on',
      'locked'   => 'unlocked',
      'unlocked' => 'locked',
      _          => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Text(device.icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                  Text(device.label,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Details
          _DetailRow('State',      currentValue.toUpperCase()),
          if (state != null) ...[
            _DetailRow('Confidence', '${(state!.confidence.value * 100).toStringAsFixed(0)}%'),
            _DetailRow('Last seen',  _timeSince(state!.lastSeen)),
          ],
          if (!device.writable)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Read-only device',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),

          // Toggle button
          if (device.writable && nextValue != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final ok = await ref
                            .read(commandNotifierProvider.notifier)
                            .send(
                              deviceId:  device.id,
                              attribute: 'state',
                              value:     nextValue,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Command failed — check daemon connection'),
                                backgroundColor: AppColors.red,
                              ),
                            );
                          }
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Set to ${nextValue.toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeSince(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final String icon;
  final bool   active;
  const _IconChip({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: active
            ? AppColors.orange.withOpacity(0.18)
            : AppColors.surfaceAlt,
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

class _ConfidenceDot extends StatelessWidget {
  final double value;
  const _ConfidenceDot({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.confidenceColor(value),
      ),
    );
  }
}