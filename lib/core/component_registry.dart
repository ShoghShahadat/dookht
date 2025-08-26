import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';

// Import all custom serializable components from the project.
import '../modules/calculations/components/calculation_result_component.dart';
import '../modules/customers/components/customer_component.dart';
import '../modules/customers/components/measurement_component.dart';
import '../modules/ui/view_manager/view_manager_component.dart';

/// Registers all custom serializable components for this application.
/// This function must be called in both the main and the logic isolates.
void registerCustomComponents() {
  final registry = ComponentFactoryRegistry.I;

  registry.register(
    'CustomerComponent',
    (json) => CustomerComponent.fromJson(json),
  );

  registry.register(
    'ViewStateComponent',
    (json) => ViewStateComponent.fromJson(json),
  );

  registry.register(
    'MeasurementComponent',
    (json) => MeasurementComponent.fromJson(json),
  );

  registry.register(
    'CalculationResultComponent',
    (json) => CalculationResultComponent.fromJson(json),
  );

  // Register the new components for the dynamic calculation engine.
  registry.register(
    'PatternMethodComponent',
    (json) => PatternMethodComponent.fromJson(json),
  );

  registry.register(
    'CalculationStateComponent',
    (json) => CalculationStateComponent.fromJson(json),
  );
}
