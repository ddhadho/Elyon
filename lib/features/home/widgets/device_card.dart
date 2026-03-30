import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarthome/core/models/device.dart';
import 'package:smarthome/core/models/device_state.dart';
import 'package:smarthome/shared/providers/api_providers.dart';
import 'package:smarthome/shared/theme/app_theme.dart';

class DeviceCard extends ConsumerWidget {
  final Device       device;
  final DeviceState? state;

  const DeviceCard({super.key, required this.device, this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveValue = _effectiveValue();
    final isSafeDefault  = state?.isSafeDefaultActive ?? false;
    final isActive       = effectiveValue == 'on'     ||
                           effectiveValue == 'locked'  ||
                           effectiveValue == 'kplc';
    final pill           = _statePill(effectiveValue);

    return GestureDetector(
      onTap: () => _showDetailSheet(context, ref, effectiveValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.orange.withOpacity(0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AppColors.orange.withOpacity(0.4)
                : const Color(0xFF2A3A5C),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon chip
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.orange.withOpacity(0.15)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(device.icon,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            // Name + state
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pill.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          pill.text,
                          style: TextStyle(
                            color: pill.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSafeDefault) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.warning_amber_rounded,
                            size: 10, color: AppColors.red),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _effectiveValue() {
    if (state == null) return '—';
    final v = state!.getEffective('state');
    if (v != '—') return v;
    if (state!.actual.isNotEmpty) {
      return state!.getEffective(state!.actual.keys.first);
    }
    return '—';
  }

  ({String text, Color color}) _statePill(String value) =>
      switch (value) {
        'locked'   => (text: 'Locked',     color: AppColors.green),
        'unlocked' => (text: 'Unlocked',   color: AppColors.yellow),
        'on'       => (text: 'Running',    color: AppColors.green),
        'off'      => (text: 'Stopped',    color: AppColors.textMuted),
        'kplc'     => (text: 'Grid power', color: AppColors.green),
        'outage'   => (text: 'Power out',  color: AppColors.red),
        '—'        => (text: 'Unknown',    color: AppColors.textMuted),
        _          => (text: value,        color: AppColors.textSecondary),
      };

  void _showDetailSheet(
      BuildContext context, WidgetRef ref, String currentValue) {
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

// ── Detail bottom sheet ────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final Device       device;
  final DeviceState? state;
  final String       currentValue;
  final WidgetRef    ref;

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
          _DetailRow('State', currentValue),
          if (state != null) ...[
            _DetailRow('Confidence',
                '${(state!.confidence.value * 100).toStringAsFixed(0)}%'),
            _DetailRow('Last seen', _timeSince(state!.lastSeen)),
          ],
          if (state?.isSafeDefaultActive ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'System acting on safe default — confidence too low',
                      style: TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!device.writable)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Read-only device',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
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
                                content: Text(
                                    'Command failed — check daemon connection'),
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
                    : Text('Set to ${nextValue.toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
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