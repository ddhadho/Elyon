import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../shared/providers/api_providers.dart';
import '../../shared/theme/app_theme.dart';

const _usefulDomains = {
  'input_boolean', 'input_select', 'switch', 'light',
  'lock', 'cover', 'fan', 'climate', 'sensor', 'binary_sensor',
};

const _kinds = [
  'Gate', 'BoreholePump', 'PowerMonitor', 'SecurityLight',
  'WaterTank', 'AlarmPanel', 'Sensor', 'Switch', 'SmartPlug', 'Unknown',
];

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  bool _showConfigured = false;

  @override
  Widget build(BuildContext context) {
    final entitiesAsync = ref.watch(haEntitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Device Discovery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(haEntitiesProvider),
          ),
        ],
      ),
      body: entitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(haEntitiesProvider),
        ),
        data: (raw) {
          final all = raw
              .cast<Map<String, dynamic>>()
              .where((e) => _usefulDomains.contains(e['domain']))
              .toList();

          final unconfigured = all.where((e) => e['already_configured'] == false).toList();
          final configured   = all.where((e) => e['already_configured'] == true).toList();
          final shown        = _showConfigured ? all : unconfigured;

          return Column(
            children: [
              _InfoBanner(
                unconfigured:   unconfigured.length,
                configured:     configured.length,
                showConfigured: _showConfigured,
                onToggle: () =>
                    setState(() => _showConfigured = !_showConfigured),
              ),
              Expanded(
                child: shown.isEmpty
                    ? _EmptyState(showingConfigured: _showConfigured)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: shown.length,
                        itemBuilder: (context, i) => _EntityTile(
                          entity: shown[i],
                          onTap: () => _openAddSheet(context, shown[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openAddSheet(BuildContext context, Map<String, dynamic> entity) {
    final isConfigured = entity['already_configured'] as bool? ?? false;
    if (isConfigured) {
      _showAlreadyConfiguredSheet(context, entity);
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => AddDeviceSheet(
          entity: entity,
          onAdded: () {
            ref.invalidate(haEntitiesProvider);
            ref.invalidate(devicesProvider);
          },
        ),
      );
    }
  }

  void _showAlreadyConfiguredSheet(
      BuildContext context, Map<String, dynamic> entity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),
            Text(
              entity['friendly_name'] as String? ?? entity['entity_id'],
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.green.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.green),
                  SizedBox(width: 10),
                  Text('Already configured in devices.toml',
                      style: TextStyle(
                          color: AppColors.green, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Add device sheet ───────────────────────────────────────────────────────────

class AddDeviceSheet extends StatefulWidget {
  final Map<String, dynamic> entity;
  final VoidCallback onAdded;

  const AddDeviceSheet({
    super.key,
    required this.entity,
    required this.onAdded,
  });

  @override
  State<AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends State<AddDeviceSheet> {
  late final TextEditingController _deviceIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _attributeCtrl;
  late final TextEditingController _decayCtrl;
  late final TextEditingController _safeDefaultValueCtrl;
  late final TextEditingController _stateMapCtrl;
  late final TextEditingController _serviceMapCtrl;

  late String _selectedKind;
  bool   _writable = false;
  bool   _saving   = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final entityId     = widget.entity['entity_id'] as String;
    final friendlyName = widget.entity['friendly_name'] as String? ?? entityId;
    final domain       = widget.entity['domain'] as String;

    final suggestedId = entityId.contains('.')
        ? entityId.split('.').last
        : entityId;

    _deviceIdCtrl        = TextEditingController(text: suggestedId);
    _nameCtrl            = TextEditingController(text: friendlyName);
    _attributeCtrl       = TextEditingController(text: _defaultAttribute(domain));
    _decayCtrl           = TextEditingController(text: '30');
    _safeDefaultValueCtrl= TextEditingController(text: _defaultSafeValue(domain));
    _stateMapCtrl        = TextEditingController(
        text: _defaultStateMap(domain));
    _serviceMapCtrl      = TextEditingController(
        text: _defaultServiceMap(domain));
    _selectedKind        = _defaultKind(domain);
    _writable            = domain != 'sensor' && domain != 'binary_sensor';
  }

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _nameCtrl.dispose();
    _attributeCtrl.dispose();
    _decayCtrl.dispose();
    _safeDefaultValueCtrl.dispose();
    _stateMapCtrl.dispose();
    _serviceMapCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _saving = true; _error = null; });

    try {
      final attribute  = _attributeCtrl.text.trim();
      final safeVal    = _safeDefaultValueCtrl.text.trim();
      final stateMap   = _parseMap(_stateMapCtrl.text);
      final serviceMap = _writable ? _parseMap(_serviceMapCtrl.text) : <String, String>{};

      final body = {
        'ha_entity_id':             widget.entity['entity_id'],
        'device_id':                _deviceIdCtrl.text.trim(),
        'name':                     _nameCtrl.text.trim(),
        'kind':                     _selectedKind,
        'attribute':                attribute,
        'confidence_decay_seconds': int.tryParse(_decayCtrl.text) ?? 30,
        'writable':                 _writable,
        'safe_default':             { attribute: safeVal },
        'state_map':                stateMap,
        'service_map':              serviceMap,
      };

      await ApiClient.instance.postDevice(body);

      widget.onAdded();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_nameCtrl.text.trim()} added — restart daemon to activate',
            ),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            const SizedBox(height: 16),

            // Title
            Text(
              'Add Device',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              widget.entity['entity_id'] as String,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),

            const SizedBox(height: 20),

            _FieldLabel('Device ID'),
            const SizedBox(height: 6),
            TextField(
              controller: _deviceIdCtrl,
              autocorrect: false,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration:
                  const InputDecoration(hintText: 'e.g. main_gate'),
            ),

            const SizedBox(height: 14),

            _FieldLabel('Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration:
                  const InputDecoration(hintText: 'e.g. Main Gate'),
            ),

            const SizedBox(height: 14),

            _FieldLabel('Kind'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedKind,
              dropdownColor: AppColors.surfaceAlt,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(),
              items: _kinds
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedKind = v ?? _selectedKind),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Attribute'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _attributeCtrl,
                        autocorrect: false,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                            hintText: 'state'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel('Confidence decay (s)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _decayCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration:
                            const InputDecoration(hintText: '30'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _FieldLabel('Safe default value'),
            const SizedBox(height: 6),
            TextField(
              controller: _safeDefaultValueCtrl,
              autocorrect: false,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration:
                  const InputDecoration(hintText: 'e.g. off, locked'),
            ),

            const SizedBox(height: 14),

            _FieldLabel('State map (one per line: ha_value=your_value)'),
            const SizedBox(height: 6),
            TextField(
              controller: _stateMapCtrl,
              maxLines: 3,
              autocorrect: false,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'monospace'),
              decoration: const InputDecoration(
                  hintText: 'on=on\noff=off'),
            ),

            const SizedBox(height: 14),

            // Writable toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Writable',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Switch(
                  value: _writable,
                  onChanged: (v) => setState(() => _writable = v),
                  activeThumbColor: AppColors.blue,
                ),
              ],
            ),

            if (_writable) ...[
              const SizedBox(height: 14),
              _FieldLabel(
                  'Service map (one per line: value=domain/service)'),
              const SizedBox(height: 6),
              TextField(
                controller: _serviceMapCtrl,
                maxLines: 3,
                autocorrect: false,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontFamily: 'monospace'),
                decoration: const InputDecoration(
                    hintText:
                        'on=input_boolean/turn_on\noff=input_boolean/turn_off'),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.red.withOpacity(0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(
                        color: AppColors.red, fontSize: 12)),
              ),
            ],

            const SizedBox(height: 20),

            // Restart notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 15, color: AppColors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Device will be written to devices.toml. '
                      'Restart the daemon to activate it.',
                      style: TextStyle(
                          color: AppColors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add Device',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Parse "key=value\nkey2=value2" into a Map
  Map<String, String> _parseMap(String text) {
    final result = <String, String>{};
    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final idx = trimmed.indexOf('=');
      if (idx < 0) continue;
      final k = trimmed.substring(0, idx).trim();
      final v = trimmed.substring(idx + 1).trim();
      if (k.isNotEmpty && v.isNotEmpty) result[k] = v;
    }
    return result;
  }

  String _defaultAttribute(String domain) =>
      domain == 'sensor' || domain == 'binary_sensor' ? 'value' : 'state';

  String _defaultSafeValue(String domain) => switch (domain) {
        'lock'                              => 'locked',
        'sensor' || 'binary_sensor'         => 'unknown',
        _                                   => 'off',
      };

  String _defaultStateMap(String domain) => switch (domain) {
        'input_boolean' || 'switch' || 'light' => 'on=on\noff=off',
        'lock'                                  => 'locked=locked\nunlocked=unlocked',
        _                                       => 'on=on\noff=off',
      };

  String _defaultServiceMap(String domain) => switch (domain) {
        'input_boolean' =>
          'on=input_boolean/turn_on\noff=input_boolean/turn_off',
        'switch' => 'on=switch/turn_on\noff=switch/turn_off',
        'light'  => 'on=light/turn_on\noff=light/turn_off',
        'lock'   => 'locked=lock/lock\nunlocked=lock/unlock',
        _        => '',
      };

  String _defaultKind(String domain) => switch (domain) {
        'input_boolean' => 'Switch',
        'switch'        => 'SmartPlug',
        'light'         => 'SecurityLight',
        'lock'          => 'Gate',
        'sensor'        => 'Sensor',
        'binary_sensor' => 'Sensor',
        _               => 'Unknown',
      };
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.textMuted,
          borderRadius: BorderRadius.circular(2),
        ),
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
          letterSpacing: 0.3,
        ),
      );
}

// ── Info banner ────────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final int  unconfigured;
  final int  configured;
  final bool showConfigured;
  final VoidCallback onToggle;

  const _InfoBanner({
    required this.unconfigured,
    required this.configured,
    required this.showConfigured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A3A5C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unconfigured available · $configured configured',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Tap a device to add it',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onToggle,
            child: Text(
              showConfigured ? 'Hide configured' : 'Show all',
              style:
                  const TextStyle(color: AppColors.blue, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Entity tile ────────────────────────────────────────────────────────────────

class _EntityTile extends StatelessWidget {
  final Map<String, dynamic> entity;
  final VoidCallback onTap;

  const _EntityTile({required this.entity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final entityId     = entity['entity_id']     as String;
    final friendlyName = entity['friendly_name'] as String? ?? entityId;
    final domain       = entity['domain']        as String;
    final state        = entity['state']         as String? ?? '';
    final isConfigured = entity['already_configured'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isConfigured
                      ? AppColors.green.withOpacity(0.12)
                      : AppColors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(_domainIcon(domain),
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friendlyName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(entityId,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(state,
                      style: TextStyle(
                          color: AppColors.stateColor(state),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  if (isConfigured) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('configured',
                          style: TextStyle(
                              color: AppColors.green, fontSize: 9)),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  String _domainIcon(String domain) => switch (domain) {
        'input_boolean' => '🔘',
        'input_select'  => '📋',
        'switch'        => '💡',
        'light'         => '💡',
        'lock'          => '🔒',
        'cover'         => '🪟',
        'fan'           => '🌀',
        'climate'       => '🌡️',
        'sensor'        => '📡',
        'binary_sensor' => '📡',
        _               => '⚙️',
      };
}

// ── Empty + error ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool showingConfigured;
  const _EmptyState({required this.showingConfigured});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            showingConfigured
                ? 'No devices found'
                : 'All entities are already configured',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}