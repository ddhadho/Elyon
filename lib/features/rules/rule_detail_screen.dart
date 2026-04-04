import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smarthome/shared/providers/api_providers.dart';
import '../../core/models/rule.dart';
import '../../core/api/api_client.dart';
import '../../shared/theme/app_theme.dart';

class RuleDetailScreen extends ConsumerWidget {
  final Rule rule;
  const RuleDetailScreen({super.key, required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(rule.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _openEditor(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Meta
          _Section(
            title: 'DETAILS',
            child: _MetaCard(rule: rule),
          ),
          const SizedBox(height: 20),

          // Trigger
          if (rule.trigger != null) ...[
            _Section(
              title: 'TRIGGER',
              child: _TriggerCard(trigger: rule.trigger!),
            ),
            const SizedBox(height: 20),
          ],

          // Conditions
          if (rule.conditions.isNotEmpty) ...[
            _Section(
              title: 'CONDITIONS (${rule.conditions.length})',
              child: Column(
                children: rule.conditions
                    .map((c) => _ConditionCard(condition: c))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Actions
          if (rule.actions.isNotEmpty) ...[
            _Section(
              title: 'ACTIONS (${rule.actions.length})',
              child: Column(
                children: rule.actions
                    .map((a) => _ActionCard(action: a))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RuleEditorScreen(rule: rule, ref: ref),
      ),
    );
  }
}

// ── Meta card ──────────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final Rule rule;
  const _MetaCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(rows: [
      _Row('ID',             rule.id),
      _Row('Conflict group', rule.conflictGroup),
      _Row('Priority',       rule.priority.toString()),
      _Row('Status',         rule.enabled ? 'Enabled' : 'Disabled',
           valueColor: rule.enabled ? AppColors.green : AppColors.textMuted),
    ]);
  }
}

// ── Trigger card ───────────────────────────────────────────────────────────────

class _TriggerCard extends StatelessWidget {
  final RuleTrigger trigger;
  const _TriggerCard({required this.trigger});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(rows: [
      _Row('Kind',      trigger.kind),
      _Row('Device',    trigger.deviceId),
      _Row('Attribute', trigger.attribute),
    ]);
  }
}

// ── Condition card ─────────────────────────────────────────────────────────────

class _ConditionCard extends StatelessWidget {
  final RuleCondition condition;
  const _ConditionCard({required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3A5C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined,
              size: 16, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              condition.summary,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action card ────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final RuleAction action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3A5C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline_rounded,
              size: 16, color: AppColors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              action.summary,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared layout helpers ──────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1,
            )),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_Row> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A5C)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return _InfoRow(row: e.value, isLast: isLast);
        }).toList(),
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.valueColor});
}

class _InfoRow extends StatelessWidget {
  final _Row row;
  final bool isLast;
  const _InfoRow({required this.row, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(row.label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              Text(row.value,
                  style: TextStyle(
                    color: row.valueColor ?? AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFF1E2D4A)),
      ],
    );
  }
}

// ── Rule editor ────────────────────────────────────────────────────────────────

class RuleEditorScreen extends StatefulWidget {
  final Rule   rule;
  final WidgetRef ref;
  const RuleEditorScreen({super.key, required this.rule, required this.ref});

  @override
  State<RuleEditorScreen> createState() => _RuleEditorScreenState();
}

class _RuleEditorScreenState extends State<RuleEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _priorityController;
  late final TextEditingController _conflictGroupController;
  late bool _enabled;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController          = TextEditingController(text: widget.rule.name);
    _priorityController      = TextEditingController(text: widget.rule.priority.toString());
    _conflictGroupController = TextEditingController(text: widget.rule.conflictGroup);
    _enabled                 = widget.rule.enabled;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priorityController.dispose();
    _conflictGroupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final updated = widget.rule.toJson()
        ..['name']           = _nameController.text.trim()
        ..['priority']       = int.tryParse(_priorityController.text) ?? widget.rule.priority
        ..['conflict_group'] = _conflictGroupController.text.trim()
        ..['enabled']        = _enabled;

      await ApiClient.instance.putRule(widget.rule.id, updated);
      widget.ref.invalidate(rulesProvider);

      if (mounted) {
        Navigator.pop(context); // back to detail
        Navigator.pop(context); // back to list
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Edit Rule'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.blue),
                  )
                : const Text('Save',
                    style: TextStyle(
                        color: AppColors.blue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FieldLabel('Name'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Rule name'),
          ),

          const SizedBox(height: 18),

          _FieldLabel('Priority (0–255)'),
          const SizedBox(height: 8),
          TextField(
            controller: _priorityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: '0–255'),
          ),

          const SizedBox(height: 18),

          _FieldLabel('Conflict group'),
          const SizedBox(height: 8),
          TextField(
            controller: _conflictGroupController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: 'e.g. power_recovery'),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Enabled',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Switch(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                activeColor: AppColors.blue,
              ),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red.withOpacity(0.3)),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.red, fontSize: 12)),
            ),
          ],

          const SizedBox(height: 32),

          // Read-only trigger/conditions/actions note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Trigger, conditions and actions are edited directly in rules.toml. '
              'Hot-reload with SIGUSR1 after saving.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      );
}