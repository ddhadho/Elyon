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
        kind: j['kind'] as String,
        deviceId: j['device_id'] as String,
        attribute: j['attribute'] as String,
      );
}

class RuleCondition {
  final String subjectDeviceId;
  final String subjectAttribute;
  final String operator;
  final String valueText;

  const RuleCondition({
    required this.subjectDeviceId,
    required this.subjectAttribute,
    required this.operator,
    required this.valueText,
  });

  factory RuleCondition.fromJson(Map<String, dynamic> j) => RuleCondition(
        subjectDeviceId: j['subject_device_id'] as String,
        subjectAttribute: j['subject_attribute'] as String,
        operator: j['operator'] as String,
        valueText: j['value_text'] as String,
      );
}

class RuleAction {
  final String deviceId;
  final String attribute;
  final String valueText;
  final int delaySeconds;

  const RuleAction({
    required this.deviceId,
    required this.attribute,
    required this.valueText,
    this.delaySeconds = 0,
  });

  factory RuleAction.fromJson(Map<String, dynamic> j) => RuleAction(
        deviceId: j['device_id'] as String,
        attribute: j['attribute'] as String,
        valueText: j['value_text'] as String,
        delaySeconds: (j['delay_seconds'] as num? ?? 0).toInt(),
      );
}

class Rule {
  final String id;
  final String name;
  final bool enabled;
  final int priority;
  final String conflictGroup;
  final RuleTrigger trigger;
  final List<RuleCondition> conditions;
  final List<RuleAction> actions;

  const Rule({
    required this.id,
    required this.name,
    required this.enabled,
    required this.priority,
    required this.conflictGroup,
    required this.trigger,
    required this.conditions,
    required this.actions,
  });

  factory Rule.fromJson(Map<String, dynamic> j) => Rule(
        id: j['id'] as String,
        name: j['name'] as String,
        enabled: j['enabled'] as bool? ?? true,
        priority: (j['priority'] as num? ?? 0).toInt(),
        conflictGroup: j['conflict_group'] as String? ?? '',
        trigger: RuleTrigger.fromJson(j['trigger'] as Map<String, dynamic>),
        conditions: (j['conditions'] as List? ?? [])
            .map((e) => RuleCondition.fromJson(e as Map<String, dynamic>))
            .toList(),
        actions: (j['actions'] as List? ?? [])
            .map((e) => RuleAction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static List<Rule> listFromJson(List<dynamic> json) =>
      json.map((e) => Rule.fromJson(e as Map<String, dynamic>)).toList();
}

class InFlightAction {
  final String ruleId;
  final String deviceId;
  final String attribute;
  final DateTime firesAt;
  final String kind;

  const InFlightAction({
    required this.ruleId,
    required this.deviceId,
    required this.attribute,
    required this.firesAt,
    required this.kind,
  });

  factory InFlightAction.fromJson(Map<String, dynamic> j) => InFlightAction(
        ruleId: j['rule_id'] as String,
        deviceId: j['device_id'] as String,
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