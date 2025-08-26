import 'package:mariya/modules/calculations/calculation_events.dart';
import 'package:mariya/modules/calculations/components/calculation_result_component.dart';
import 'package:mariya/modules/customers/components/measurement_component.dart';
import 'package:nexus/nexus.dart';

/// The core logic system that performs all pattern calculations.
class CalculationSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdateMeasurementEvent>(_onUpdateMeasurement);
    listen<PerformCalculationEvent>(_onPerformCalculation);
  }

  /// Updates and saves a single measurement field for a customer.
  void _onUpdateMeasurement(UpdateMeasurementEvent event) {
    final customer = world.entities[event.customerId];
    if (customer == null) return;

    final currentMeasurements =
        customer.get<MeasurementComponent>() ?? MeasurementComponent();

    // Create a new map with the updated value.
    final newJson = Map<String, dynamic>.from(currentMeasurements.toJson());
    newJson[event.fieldKey] = event.value;

    // Create a new component instance with the updated data.
    customer.add(MeasurementComponent.fromJson(newJson));

    // Auto-save after every change.
    world.eventBus.fire(SaveDataEvent());
  }

  /// Performs all calculations based on the customer's current measurements.
  void _onPerformCalculation(PerformCalculationEvent event) {
    final customer = world.entities[event.customerId];
    final measurements = customer?.get<MeasurementComponent>();
    if (customer == null || measurements == null) return;

    // --- Your Calculation Logic Translated to Code ---

    // Bust: 1/4 measurement + ease (conditional)
    double? bodiceBustWidth;
    if (measurements.bustCircumference != null) {
      final bust = measurements.bustCircumference!;
      final ease = bust < 104 ? 1.0 : 2.0; // Your smart rule!
      bodiceBustWidth = (bust / 4) + ease;
    }

    // Waist: 1/4 measurement (darts are handled in pattern drafting)
    double? bodiceWaistWidth = measurements.waistCircumference != null
        ? (measurements.waistCircumference! / 4)
        : null;

    // Hip: 1/4 measurement + ease
    double? bodiceHipWidth = measurements.hipCircumference != null
        ? (measurements.hipCircumference! / 4) + 2.0
        : null;

    // Front Interscye: 1/2 measurement + correction
    double? frontInterscyeWidth = measurements.frontInterscye != null
        ? (measurements.frontInterscye! / 2) + 1.0
        : null;

    // Back Interscye: 1/2 measurement - correction
    double? backInterscyeWidth = measurements.backInterscye != null
        ? (measurements.backInterscye! / 2) - 1.0
        : null;

    // Sleeve Width: 1/2 measurement + ease
    double? sleeveWidth = measurements.armCircumference != null
        ? (measurements.armCircumference! / 2) + 2.0
        : null;

    // Sleeve Cuff: 1/2 measurement
    double? sleeveCuffWidth = measurements.wristCircumference != null
        ? (measurements.wristCircumference! / 2)
        : null;

    // Create the result component and add it to the customer entity.
    final results = CalculationResultComponent(
      bodiceBustWidth: bodiceBustWidth,
      bodiceWaistWidth: bodiceWaistWidth,
      bodiceHipWidth: bodiceHipWidth,
      frontInterscyeWidth: frontInterscyeWidth,
      backInterscyeWidth: backInterscyeWidth,
      sleeveWidth: sleeveWidth,
      sleeveCuffWidth: sleeveCuffWidth,
    );

    customer.add(results);
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
