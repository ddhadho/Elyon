import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/api_providers.dart';
import '../../core/models/rule.dart';
import '../../core/api/api_client.dart';
import '../../shared/theme/app_theme.dart';
import 'rule_detail_screen.dart';

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(rulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rules')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (state) {
          final rules    = state.rules;
          final inFlight = state.inFlight;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (inFlight.isNotEmpty) ...[
                _SectionHeader('IN-FLIGHT (${inFlight.length})'),
                const SizedBox(height: 8),
                ...inFlight.map((a) => _InFlightTile(action: a)),
                const SizedBox(height: 24),
              ],
              _SectionHeader('RULES (${rules.length})'),
              const SizedBox(height: 8),
              ...rules.map(
                (r) => _RuleTile(
                  rule: r,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RuleDetailScreen(rule: r),
                    ),
                  ),
                  onToggle: () async {
                    if (r.enabled) {
                      await ApiClient.instance.disableRule(r.id);
                    } else {
                      await ApiClient.instance.enableRule(r.id);
                    }
                    ref.invalidate(rulesProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 1,
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final Rule rule;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _RuleTile({
    required this.rule,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rule.enabled ? AppColors.green : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${rule.conflictGroup} · priority ${rule.priority}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Switch(
                value: rule.enabled,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InFlightTile extends StatelessWidget {
  final InFlightAction action;
  const _InFlightTile({required this.action});

  @override
  Widget build(BuildContext context) {
    final remaining = action.firesAt.difference(DateTime.now());
    final label = remaining.isNegative
        ? 'firing now'
        : 'fires in ${remaining.inSeconds}s';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.timer_outlined, color: AppColors.yellow),
        title: Text('${action.deviceId} → ${action.attribute}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        subtitle: Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        dense: true,
      ),
    );
  }
}