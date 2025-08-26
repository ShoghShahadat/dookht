import 'package:nexus/nexus.dart';

/// Event fired to update a single measurement value for a customer.
/// This is used for auto-saving the form fields.
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

/// Event fired to command the CalculationSystem to perform all pattern calculations
/// for a specific customer using their currently saved measurements.
class PerformCalculationEvent {
  final EntityId customerId;

  PerformCalculationEvent(this.customerId);
}
