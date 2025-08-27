// FILE: lib/core/type_id_provider.dart
// (English comments for code clarity)
// FINAL FIX v9: This function is now lean and focused. It only needs to
// resolve type IDs for the custom components within this specific application.
// Core Nexus components are handled automatically by the package.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_result_component.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:tailor_assistant/modules/customers/components/measurement_component.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';

/// The application's implementation of the ComponentTypeIdProvider contract.
/// It returns the stable, static type ID for a given component instance.
String appComponentTypeIdProvider(Component component) {
  // --- Custom Application Components ---
  if (component is CustomerComponent) return CustomerComponent.typeId;
  if (component is MeasurementComponent) return MeasurementComponent.typeId;
  if (component is CalculationResultComponent)
    return CalculationResultComponent.typeId;
  if (component is CalculationStateComponent)
    return CalculationStateComponent.typeId;
  if (component is PatternMethodComponent) return PatternMethodComponent.typeId;
  if (component is ViewStateComponent) return ViewStateComponent.typeId;

  // --- Fallback for Core Nexus Components ---
  // For any component not defined above (i.e., a core Nexus component),
  // fall back to the runtimeType string. The core registry uses this key.
  return component.runtimeType.toString();
}
