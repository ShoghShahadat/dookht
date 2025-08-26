import 'package:collection/collection.dart';
import 'package:tailor_assistant/modules/calculations/calculation_events.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_result_component.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/customers/components/measurement_component.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:expressions/expressions.dart';

/// The core logic system that performs all pattern calculations dynamically.
class CalculationSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdateMeasurementEvent>(_onUpdateMeasurement);
    listen<PerformCalculationEvent>(_onPerformCalculation);
    listen<SelectPatternMethodEvent>(_onSelectPatternMethod);
    listen<UpdateCalculationVariableEvent>(_onUpdateVariable);
  }

  void _onUpdateVariable(UpdateCalculationVariableEvent event) {
    final customer = world.entities[event.customerId];
    if (customer == null) return;

    final currentState = customer.get<CalculationStateComponent>() ??
        CalculationStateComponent();
    final newVariables = Map<String, double>.from(currentState.variableValues);

    if (event.value != null) {
      newVariables[event.variableKey] = event.value!;
    } else {
      newVariables.remove(event.variableKey);
    }

    customer.add(CalculationStateComponent(
      selectedMethodId: currentState.selectedMethodId,
      variableValues: newVariables,
    ));

    world.eventBus.fire(SaveDataEvent());
  }

  void _onSelectPatternMethod(SelectPatternMethodEvent event) {
    final customer = world.entities[event.customerId];
    if (customer == null) return;

    final currentState = customer.get<CalculationStateComponent>() ??
        CalculationStateComponent();

    customer.add(CalculationStateComponent(
      selectedMethodId: event.methodId,
      variableValues:
          currentState.variableValues, // Preserve existing variables
    ));
  }

  void _onUpdateMeasurement(UpdateMeasurementEvent event) {
    final customer = world.entities[event.customerId];
    if (customer == null) return;

    final currentMeasurements =
        customer.get<MeasurementComponent>() ?? MeasurementComponent();

    final newJson = Map<String, dynamic>.from(currentMeasurements.toJson());
    newJson[event.fieldKey] = event.value;

    customer.add(MeasurementComponent.fromJson(newJson));
    world.eventBus.fire(SaveDataEvent());
  }

  void _onPerformCalculation(PerformCalculationEvent event) {
    final customer = world.entities[event.customerId];
    if (customer == null) return;

    final measurements = customer.get<MeasurementComponent>();
    final calcState = customer.get<CalculationStateComponent>();
    if (measurements == null || calcState == null) return;

    // Find the selected method, or default to the first available one.
    EntityId? methodId = calcState.selectedMethodId;
    methodId ??= world.entities.values
        .firstWhereOrNull((e) => e.has<PatternMethodComponent>())
        ?.id;

    if (methodId == null) {
      print("Calculation Error: No pattern methods found.");
      return;
    }

    // Update the state to ensure the default method ID is saved.
    if (calcState.selectedMethodId == null) {
      customer.add(CalculationStateComponent(
          selectedMethodId: methodId,
          variableValues: calcState.variableValues));
    }

    final methodEntity = world.entities[methodId];
    final method = methodEntity?.get<PatternMethodComponent>();
    if (method == null) {
      print(
          "Calculation Error: Selected pattern method (ID: $methodId) not found.");
      return;
    }

    // --- Dynamic Calculation Logic ---
    final expressionContext = <String, dynamic>{};
    // 1. Add all raw measurements to the context.
    expressionContext.addAll(
        measurements.toJson()..removeWhere((key, value) => value == null));

    // 2. Add all dynamic variables to the context, using defaults if not provided.
    for (var variable in method.variables) {
      expressionContext[variable.key] =
          calcState.variableValues[variable.key] ?? variable.defaultValue;
    }

    final results = <String, double?>{};
    final evaluator = const ExpressionEvaluator();

    // 3. Evaluate each formula.
    for (final formula in method.formulas) {
      try {
        final expression = Expression.parse(formula.expression);
        final result = evaluator.eval(expression, expressionContext);
        if (result is num) {
          results[formula.resultKey] = result.toDouble();
          // Add the result to the context so it can be used in subsequent formulas.
          expressionContext[formula.resultKey] = result.toDouble();
        }
      } catch (e) {
        print("Error evaluating formula for '${formula.resultKey}': $e");
        results[formula.resultKey] = null;
      }
    }

    // 4. Create the result component and add it to the customer entity.
    customer.add(CalculationResultComponent.fromJson(results));
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
