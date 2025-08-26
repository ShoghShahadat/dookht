import 'package:nexus/nexus.dart';

// Event fired to update a single measurement value for a customer.
class UpdateMeasurementEvent {
  final EntityId customerId;
  final String fieldKey; // e.g., 'bustCircumference'
  final double? value;

  UpdateMeasurementEvent({
    required this.customerId,
    required this.fieldKey,
    this.value,
  });
}

// Event fired to command the CalculationSystem to perform all pattern calculations.
class PerformCalculationEvent {
  final EntityId customerId;

  PerformCalculationEvent(this.customerId);
}

// Event fired when the user selects a different pattern method from the dropdown.
class SelectPatternMethodEvent {
  final EntityId customerId;
  final EntityId methodId;

  SelectPatternMethodEvent({required this.customerId, required this.methodId});
}

// Event fired when the user changes the value of a dynamic variable (e.g., ease).
class UpdateCalculationVariableEvent {
  final EntityId customerId;
  final String variableKey;
  final double? value;

  UpdateCalculationVariableEvent({
    required this.customerId,
    required this.variableKey,
    this.value,
  });
}
