// FILE: lib/modules/calculations/components/calculation_state_component.dart
// (English comments for code clarity)
// FINAL FIX v7: Added a static, stable typeId for robust serialization.

import 'package:nexus/nexus.dart';

class CalculationStateComponent extends Component with SerializableComponent {
  static const String typeId = 'calculation_state';

  final EntityId? selectedMethodId;
  final Map<String, double> variableValues;

  CalculationStateComponent({
    this.selectedMethodId,
    Map<String, double>? variableValues,
  }) : variableValues = variableValues ?? {};

  factory CalculationStateComponent.fromJson(Map<String, dynamic> json) {
    return CalculationStateComponent(
      selectedMethodId: json['selectedMethodId'] as EntityId?,
      variableValues: (json['variableValues'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'selectedMethodId': selectedMethodId,
        'variableValues': variableValues,
      };

  @override
  List<Object?> get props => [selectedMethodId, variableValues];
}
