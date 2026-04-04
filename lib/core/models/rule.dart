class RuleTrigger {
  final String kind;
  final String deviceId;
  final String attribute;

  const RuleTrigger({
    required this.kind,
    required this.deviceId,
    required this.attribute,
  });

  factory RuleTrigger.fromJson(Map<String, dynamic> j) => RuleTrigger(
        kind:      j['kind']      as String,
        deviceId:  j['device_id'] as String,
        attribute: j['attribute'] as String,
      );

  Map<String, dynamic> toJson() => {
        'kind':      kind,
        'device_id': deviceId,
        'attribute': attribute,
      };
}

class RuleCondition {
  final String subjectDeviceId;
  final String subjectAttribute;
  final String operator;
  final String? valueText;
  final bool?   valueBool;
  final int?    valueInt;
  final double? valueFloat;
  final double? valueRangeMin;
  final double? valueRangeMax;
  final int?    durationSeconds;

  const RuleCondition({
    required this.subjectDeviceId,
    required this.subjectAttribute,
    required this.operator,
    this.valueText,
    this.valueBool,
    this.valueInt,
    this.valueFloat,
    this.valueRangeMin,
    this.valueRangeMax,
    this.durationSeconds,
  });

  /// Human-readable summary for display in the rule builder
  String get summary {
    final subject = '$subjectDeviceId.$subjectAttribute';
    final val = valueText ?? valueBool?.toString() ?? valueInt?.toString() ?? '';
    return switch (operator) {
      'Equals'              => '$subject = $val',
      'NotEquals'           => '$subject ≠ $val',
      'WasPreviously'       => '$subject was $val',
      'IsUnknown'           => '$subject is unknown',
      'GreaterThan'         => '$subject > $val',
      'LessThan'            => '$subject < $val',
      'GreaterThanOrEqual'  => '$subject ≥ $val',
      'LessThanOrEqual'     => '$subject ≤ $val',
      'Between'             => '$subject between $valueRangeMin–$valueRangeMax',
      _                     => '$subject $operator $val',
    };
  }

  factory RuleCondition.fromJson(Map<String, dynamic> j) => RuleCondition(
        subjectDeviceId:  j['subject_device_id']  as String,
        subjectAttribute: j['subject_attribute']  as String,
        operator:         j['operator']           as String,
        valueText:        j['value_text']         as String?,
        valueBool:        j['value_bool']         as bool?,
        valueInt:         j['value_int']          as int?,
        valueFloat:       (j['value_float']       as num?)?.toDouble(),
        valueRangeMin:    (j['value_range_min']   as num?)?.toDouble(),
        valueRangeMax:    (j['value_range_max']   as num?)?.toDouble(),
        durationSeconds:  j['duration_seconds']   as int?,
      );

  Map<String, dynamic> toJson() => {
        'subject_device_id':  subjectDeviceId,
        'subject_attribute':  subjectAttribute,
        'operator':           operator,
        'value_text':         valueText,
        'value_bool':         valueBool,
        'value_int':          valueInt,
        'value_float':        valueFloat,
        'value_range_min':    valueRangeMin,
        'value_range_max':    valueRangeMax,
        'duration_seconds':   durationSeconds,
      };
}

class RuleAction {
  final String  deviceId;
  final String  attribute;
  final String? valueText;
  final bool?   valueBool;
  final int?    valueInt;
  final double? valueFloat;
  final int?    delaySeconds;

  const RuleAction({
    required this.deviceId,
    required this.attribute,
    this.valueText,
    this.valueBool,
    this.valueInt,
    this.valueFloat,
    this.delaySeconds,
  });

  /// Human-readable summary for display
  String get summary {
    final val = valueText ?? valueBool?.toString() ?? valueInt?.toString() ?? '';
    final delay = (delaySeconds != null && delaySeconds! > 0)
        ? ' (after ${delaySeconds}s)'
        : '';
    return '$deviceId → $attribute = $val$delay';
  }

  factory RuleAction.fromJson(Map<String, dynamic> j) => RuleAction(
        deviceId:     j['device_id']     as String,
        attribute:    j['attribute']     as String,
        valueText:    j['value_text']    as String?,
        valueBool:    j['value_bool']    as bool?,
        valueInt:     j['value_int']     as int?,
        valueFloat:   (j['value_float']  as num?)?.toDouble(),
        delaySeconds: j['delay_seconds'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'device_id':     deviceId,
        'attribute':     attribute,
        'value_text':    valueText,
        'value_bool':    valueBool,
        'value_int':     valueInt,
        'value_float':   valueFloat,
        'delay_seconds': delaySeconds,
      };
}

class Rule {
  final String id;
  final String name;
  final bool   enabled;
  final int    priority;
  final String conflictGroup;
  final bool?  stateful;
  final RuleTrigger?       trigger;
  final List<RuleCondition> conditions;
  final List<RuleAction>    actions;

  const Rule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.priority,
    required this.conflictGroup,
    this.stateful,
    this.trigger,
    this.conditions = const [],
    this.actions    = const [],
  });

  factory Rule.fromJson(Map<String, dynamic> j) => Rule(
        id:            j['id']             as String,
        name:          j['name']           as String,
        enabled:       j['enabled']        as bool? ?? true,
        priority:      (j['priority']      as num? ?? 0).toInt(),
        conflictGroup: j['conflict_group'] as String? ?? '',
        stateful:      j['stateful']       as bool?,
        trigger: j['trigger'] != null
            ? RuleTrigger.fromJson(j['trigger'] as Map<String, dynamic>)
            : null,
        conditions: (j['conditions'] as List? ?? [])
            .map((e) => RuleCondition.fromJson(e as Map<String, dynamic>))
            .toList(),
        actions: (j['actions'] as List? ?? [])
            .map((e) => RuleAction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id':             id,
        'name':           name,
        'enabled':        enabled,
        'priority':       priority,
        'conflict_group': conflictGroup,
        'trigger':        trigger?.toJson(),
        'conditions':     conditions.map((c) => c.toJson()).toList(),
        'actions':        actions.map((a) => a.toJson()).toList(),
      };

  static List<Rule> listFromJson(List<dynamic> json) =>
      json.map((e) => Rule.fromJson(e as Map<String, dynamic>)).toList();
}

class InFlightAction {
  final String   ruleId;
  final String   deviceId;
  final String   attribute;
  final DateTime firesAt;
  final String   kind;

  const InFlightAction({
    required this.ruleId,
    required this.deviceId,
    required this.attribute,
    required this.firesAt,
    required this.kind,
  });

  factory InFlightAction.fromJson(Map<String, dynamic> j) => InFlightAction(
        ruleId:    j['rule_id']    as String,
        deviceId:  j['device_id'] as String,
        attribute: j['attribute'] as String,
        firesAt: DateTime.fromMillisecondsSinceEpoch(
          (j['fires_at_ms'] as num).toInt(),
        ),
        kind: j['kind'] as String,
      );

  static List<InFlightAction> listFromJson(List<dynamic> json) => json
      .map((e) => InFlightAction.fromJson(e as Map<String, dynamic>))
      .toList();
}