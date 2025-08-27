// FILE: lib/modules/modules/calculations/calculation_system.dart
// (English comments for code clarity)

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

  // --- DEFINITIVE FIX: A recursive function to correctly extract all identifiers from an expression tree. ---
  // This replaces the non-existent `expression.identifiers()` method.
  Set<String> _getIdentifiers(Expression expression) {
    final identifiers = <String>{};
    if (expression is Variable) {
      identifiers.add(expression.identifier.name);
    } else if (expression is MemberExpression) {
      // This is a simplified handling. A full implementation might need to
      // reconstruct the full member access path (e.g., 'a.b.c').
      // For this app's use case, just getting the root object is enough.
      identifiers.addAll(_getIdentifiers(expression.object));
    } else if (expression is IndexExpression) {
      identifiers.addAll(_getIdentifiers(expression.object));
      identifiers.addAll(_getIdentifiers(expression.index));
    } else if (expression is CallExpression) {
      identifiers.addAll(_getIdentifiers(expression.callee));
      for (var arg in expression.arguments) {
        identifiers.addAll(_getIdentifiers(arg));
      }
    } else if (expression is UnaryExpression) {
      identifiers.addAll(_getIdentifiers(expression.argument));
    } else if (expression is BinaryExpression) {
      identifiers.addAll(_getIdentifiers(expression.left));
      identifiers.addAll(_getIdentifiers(expression.right));
    } else if (expression is ConditionalExpression) {
      identifiers.addAll(_getIdentifiers(expression.test));
      identifiers.addAll(_getIdentifiers(expression.consequent));
      identifiers.addAll(_getIdentifiers(expression.alternate));
    } else if (expression is Literal) {
      // Literals (like numbers or strings) don't have identifiers.
    }
    return identifiers;
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
      variableValues: currentState.variableValues,
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

    EntityId? methodId = calcState.selectedMethodId ??
        world.entities.values
            .firstWhereOrNull((e) => e.has<PatternMethodComponent>())
            ?.id;

    if (methodId == null) {
      print("Calculation Error: No pattern methods found.");
      return;
    }

    if (calcState.selectedMethodId == null) {
      customer.add(CalculationStateComponent(
          selectedMethodId: methodId,
          variableValues: calcState.variableValues));
    }

    final methodEntity = world.entities[methodId];
    final method = methodEntity?.get<PatternMethodComponent>();
    if (method == null) return;

    final expressionContext = <String, dynamic>{};
    expressionContext.addAll(
        measurements.toJson()..removeWhere((key, value) => value == null));

    for (var variable in method.variables) {
      expressionContext[variable.key] =
          calcState.variableValues[variable.key] ?? variable.defaultValue;
    }

    final results = <String, double?>{};
    final evaluator = const ExpressionEvaluator();

    for (final formula in method.formulas) {
      try {
        final expression = Expression.parse(formula.expression);

        final requiredVars = _getIdentifiers(expression);

        final canEvaluate =
            requiredVars.every((v) => expressionContext.containsKey(v));

        if (canEvaluate) {
          final result = evaluator.eval(expression, expressionContext);
          if (result is num) {
            results[formula.resultKey] = result.toDouble();
            expressionContext[formula.resultKey] = result.toDouble();
          }
        } else {
          results[formula.resultKey] = null;
        }
      } catch (e) {
        print("Error evaluating formula for '${formula.resultKey}': $e");
        results[formula.resultKey] = null;
      }
    }

    customer.add(CalculationResultComponent.fromJson(results));
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
