// FILE: lib/core/component_registry.dart
// (English comments for code clarity)
// FINAL FIX v7: Switched from string-based type names to stable, static type IDs
// to make the serialization process robust against code minification in release mode.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';

import '../modules/calculations/components/calculation_result_component.dart';
import '../modules/customers/components/customer_component.dart';
import '../modules/customers/components/measurement_component.dart';
import '../modules/ui/view_manager/view_manager_component.dart';

/// Registers all custom serializable components for this application.
void registerCustomComponents() {
  final registry = ComponentFactoryRegistry.I;

  registry.register(
    CustomerComponent.typeId, // Use static typeId
    (json) => CustomerComponent.fromJson(json),
  );

  registry.register(
    ViewStateComponent.typeId, // Use static typeId
    (json) => ViewStateComponent.fromJson(json),
  );

  registry.register(
    MeasurementComponent.typeId, // Use static typeId
    (json) => MeasurementComponent.fromJson(json),
  );

  registry.register(
    CalculationResultComponent.typeId, // Use static typeId
    (json) => CalculationResultComponent.fromJson(json),
  );

  registry.register(
    PatternMethodComponent.typeId, // Use static typeId
    (json) => PatternMethodComponent.fromJson(json),
  );

  registry.register(
    CalculationStateComponent.typeId, // Use static typeId
    (json) => CalculationStateComponent.fromJson(json),
  );
}
