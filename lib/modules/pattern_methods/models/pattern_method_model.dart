// FILE: lib/modules/pattern_methods/models/pattern_method_model.dart
// (English comments for code clarity)
// MODIFIED v2.0: Added `visualGraphData` to the Formula class to store the
// serialized state of the visual editor for each formula.

import 'package:nexus/nexus.dart';

// Defines the structure for a single calculation formula.
class Formula {
  final String resultKey; // e.g., 'bodiceBustWidth'
  final String expression; // e.g., '({bustCircumference} / 4) + {ease}'
  final String label; // e.g., 'عرض کادر سینه'

  // NEW: Stores the serialized JSON of the visual graph (nodes and connections).
  final Map<String, dynamic>? visualGraphData;

  Formula({
    required this.resultKey,
    required this.expression,
    required this.label,
    this.visualGraphData,
  });

  Formula copyWith({
    String? resultKey,
    String? expression,
    String? label,
    Map<String, dynamic>? visualGraphData,
  }) {
    return Formula(
      resultKey: resultKey ?? this.resultKey,
      expression: expression ?? this.expression,
      label: label ?? this.label,
      visualGraphData: visualGraphData ?? this.visualGraphData,
    );
  }

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      resultKey: json['resultKey'] as String,
      expression: json['expression'] as String,
      label: json['label'] as String,
      visualGraphData: json['visualGraphData'] != null
          ? Map<String, dynamic>.from(json['visualGraphData'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'resultKey': resultKey,
        'expression': expression,
        'label': label,
        'visualGraphData': visualGraphData,
      };
}

// Defines the structure for a dynamic input variable.
class DynamicVariable {
  final String key; // e.g., 'ease'
  final String label; // e.g., 'میزان آزادی'
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

// A serializable component that holds the definition of a pattern-making method.
class PatternMethodComponent extends Component with SerializableComponent {
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
