import 'package:nexus/nexus.dart';

// This component holds the transient state of the calculation page for a specific customer.
class CalculationStateComponent extends Component with SerializableComponent {
  // The ID of the currently selected pattern method entity.
  final EntityId? selectedMethodId;

  // A map of dynamic variable values provided by the user (e.g., {'ease': 1.5}).
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
