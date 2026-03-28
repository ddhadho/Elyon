import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarthome/shared/providers/api_providers.dart';
import '../../core/models/rule.dart';
import '../../core/api/api_client.dart';

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
          final rules = state.rules;
          final inFlight = state.inFlight;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (inFlight.isNotEmpty) ...[
                _SectionHeader('In-flight actions (${inFlight.length})'),
                const SizedBox(height: 8),
                ...inFlight.map((a) => _InFlightTile(action: a)),
                const SizedBox(height: 24),
              ],
              _SectionHeader('Rules (${rules.length})'),
              const SizedBox(height: 8),
              ...rules.map(
                (r) => _RuleTile(
                  rule: r,
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
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white.withOpacity(0.4),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final Rule rule;
  final VoidCallback onToggle;

  const _RuleTile({required this.rule, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rule.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Switch(value: rule.enabled, onChanged: (_) => onToggle()),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${rule.actions.length} action${rule.actions.length == 1 ? '' : 's'} · '
              'priority ${rule.priority}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
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
        leading: const Icon(Icons.timer_outlined, color: Color(0xFFFBBF24)),
        title: Text('${action.deviceId} → ${action.attribute}'),
        subtitle: Text(label),
        dense: true,
      ),
    );
  }
}