// FILE: lib/modules/pattern_methods/models/pattern_method_model.dart
// (English comments for code clarity)
// FINAL FIX v7: Added a static, stable typeId for robust serialization.

import 'package:nexus/nexus.dart';

class Formula {
  final String resultKey;
  final String expression;
  final String label;

  Formula(
      {required this.resultKey, required this.expression, required this.label});

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      resultKey: json['resultKey'] as String,
      expression: json['expression'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'resultKey': resultKey,
        'expression': expression,
        'label': label,
      };
}

class DynamicVariable {
  final String key;
  final String label;
  final double defaultValue;

  DynamicVariable(
      {required this.key, required this.label, required this.defaultValue});

  factory DynamicVariable.fromJson(Map<String, dynamic> json) {
    return DynamicVariable(
      key: json['key'] as String,
      label: json['label'] as String,
      defaultValue: (json['defaultValue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'defaultValue': defaultValue,
      };
}

class PatternMethodComponent extends Component with SerializableComponent {
  static const String typeId = 'pattern_method';

  final String methodId;
  final String name;
  final List<Formula> formulas;
  final List<DynamicVariable> variables;

  PatternMethodComponent({
    required this.methodId,
    required this.name,
    required this.formulas,
    required this.variables,
  });

  factory PatternMethodComponent.fromJson(Map<String, dynamic> json) {
    return PatternMethodComponent(
      methodId: json['methodId'] as String,
      name: json['name'] as String,
      formulas: (json['formulas'] as List)
          .map((f) => Formula.fromJson(f as Map<String, dynamic>))
          .toList(),
      variables: (json['variables'] as List)
          .map((v) => DynamicVariable.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'methodId': methodId,
        'name': name,
        'formulas': formulas.map((f) => f.toJson()).toList(),
        'variables': variables.map((v) => v.toJson()).toList(),
      };

  @override
  List<Object?> get props => [methodId, name, formulas, variables];
}
