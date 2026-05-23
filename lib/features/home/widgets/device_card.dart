import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elyon/core/models/device.dart';
import 'package:elyon/core/models/device_state.dart';
import 'package:elyon/shared/providers/api_providers.dart';
import 'package:elyon/shared/theme/app_theme.dart';

class DeviceCard extends ConsumerStatefulWidget {
  final Device device;
  final DeviceState? state;

  const DeviceCard({super.key, required this.device, this.state});

  @override
  ConsumerState<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends ConsumerState<DeviceCard> {
  bool _toggling = false;

  String _effectiveValue() {
    if (widget.state == null) return '—';
    final v = widget.state!.getEffective('state');
    if (v != '—') return v;
    if (widget.state!.actual.isNotEmpty) {
      return widget.state!.getEffective(widget.state!.actual.keys.first);
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

  String? _nextValue(String current) => switch (current) {
    'on'       => 'off',
    'off'      => 'on',
    'locked'   => 'unlocked',
    'unlocked' => 'locked',
    _          => null,
  };

  Future<void> _handleToggle(String currentValue) async {
    final next = _nextValue(currentValue);
    if (next == null || !widget.device.writable) return;

    HapticFeedback.lightImpact();
    setState(() => _toggling = true);

    final ok = await ref.read(commandNotifierProvider.notifier).send(
      deviceId:  widget.device.id,
      attribute: 'state',
      value:     next,
    );

    if (mounted) {
      setState(() => _toggling = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Command failed — check daemon connection'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _openSheet(String currentValue) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DetailSheet(
        device: widget.device,
        state: widget.state,
        currentValue: currentValue,
        ref: ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveValue = _effectiveValue();
    final isSafeDefault  = widget.state?.isSafeDefaultActive ?? false;
    final isActive       = effectiveValue == 'on'    ||
                           effectiveValue == 'locked' ||
                           effectiveValue == 'kplc';
    final pill           = _statePill(effectiveValue);
    final confidence     = widget.state?.confidence.value ?? 0.0;
    final canToggle      = widget.device.writable &&
                           _nextValue(effectiveValue) != null;

    return GestureDetector(
      onTap: () => _openSheet(effectiveValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.orange.withOpacity(0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? AppColors.orange.withOpacity(0.35)
                : const Color(0x12000000),
            width: isActive ? 1.0 : 0.5,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Top row: icon + safe default dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.orange.withOpacity(0.15)
                        : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(widget.device.icon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                if (isSafeDefault)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.surface, width: 1.5),
                    ),
                  ),
              ],
            ),

            const Spacer(),

            // ── Device name
            Text(
              widget.device.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // ── Status pill
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pill.color,
                  ),
                ),
                const SizedBox(width: 5),
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
              ],
            ),

            const SizedBox(height: 10),

            // ── Bottom row: confidence dots + toggle
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Confidence dots
                _ConfidenceDots(value: confidence),

                const Spacer(),

                // Toggle
                if (canToggle)
                  GestureDetector(
                    onTap: () => _handleToggle(effectiveValue),
                    // Absorb tap so it doesn't bubble up to the card's onTap
                    behavior: HitTestBehavior.opaque,
                    child: _toggling
                        ? SizedBox(
                            width: 36, height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.orange,
                                ),
                              ),
                            ),
                          )
                        : _TogglePill(isOn: isActive),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle pill ───────────────────────────────────────────────────────────────

class _TogglePill extends StatelessWidget {
  final bool isOn;
  const _TogglePill({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36, height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isOn
            ? AppColors.orange
            : AppColors.textMuted.withOpacity(0.25),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16, height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confidence dots ───────────────────────────────────────────────────────────

class _ConfidenceDots extends StatelessWidget {
  final double value; // 0.0 – 1.0
  const _ConfidenceDots({required this.value});

  @override
  Widget build(BuildContext context) {
    final filled = (value * 5).round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final active = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 6, height: 6,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.confidenceColor(value)
                : AppColors.textMuted.withOpacity(0.25),
          ),
        );
      }),
    );
  }
}

// ── Detail bottom sheet ───────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final Device device;
  final DeviceState? state;
  final String currentValue;
  final WidgetRef ref;

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
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon + name
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

          // Safe default warning
          if (state?.isSafeDefaultActive ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.yellow.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.yellow),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'System acting on safe default — confidence too low',
                      style:
                          TextStyle(color: AppColors.yellow, fontSize: 12),
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

          // Action button
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
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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