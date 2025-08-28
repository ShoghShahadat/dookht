// FILE: lib/modules/visual_formula_editor/formula_evaluation_system.dart
// (English comments for code clarity)
// FIX v5.0: Added a default case to the operator switch statement to make it robust
// and satisfy Dart's null safety analysis completely.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

/// The brain of the visual editor. Evaluates the node graph in response to events.
class FormulaEvaluationSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<RecalculateGraphEvent>(_onRecalculate);
  }

  void _onRecalculate(RecalculateGraphEvent event) {
    final canvasEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
    if (canvasEntity == null) return;

    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    final nodes =
        world.entities.values.where((e) => e.has<NodeComponent>()).toList();
    final connections = world.entities.values
        .where((e) => e.has<ConnectionComponent>())
        .toList();

    for (final node in nodes) {
      if (node.has<NodeStateComponent>()) {
        node.remove<NodeStateComponent>();
      }
    }

    final sortedNodes = _topologicalSort(nodes, connections);

    for (final node in sortedNodes) {
      _evaluateNode(node, canvasState.previewInputValues);
    }
  }

  void _evaluateNode(Entity node, Map<String, double> previewInputs) {
    final nodeComp = node.get<NodeComponent>()!;
    final inputs = <String, dynamic>{};
    String? error;

    for (final inputPort in nodeComp.inputs) {
      final connection = world.entities.values.firstWhereOrNull((e) {
        final c = e.get<ConnectionComponent>();
        return c != null && c.toNodeId == node.id && c.toPortId == inputPort.id;
      });

      if (connection != null) {
        final connComp = connection.get<ConnectionComponent>()!;
        final fromNode = world.entities[connComp.fromNodeId];
        final fromNodeState = fromNode?.get<NodeStateComponent>();
        inputs[inputPort.id] = fromNodeState?.outputValues[connComp.fromPortId];
      }
    }

    final outputValues = <String, dynamic>{};

    try {
      switch (nodeComp.type) {
        case NodeType.input:
          final inputId =
              nodeComp.data['inputId'] as String? ?? node.id.toString();
          outputValues['value'] = previewInputs[inputId];
          break;
        case NodeType.constant:
          outputValues['value'] = nodeComp.data['value'];
          break;
        case NodeType.operator:
          final operator = nodeComp.data['operator'] as String? ?? '+';
          final inputValues = inputs.values.whereType<num>().toList();

          if (inputValues.isEmpty) {
            // No error, just no output
          } else if (inputValues.length == 1) {
            outputValues['result'] = inputValues.first;
          } else {
            num result = 0;
            switch (operator) {
              case '+':
                result = inputValues.reduce((a, b) => a + b);
                break;
              case '-':
                result = inputValues
                    .sublist(1)
                    .fold(inputValues[0], (prev, e) => prev - e);
                break;
              case '*':
                result = inputValues.reduce((a, b) => a * b);
                break;
              case '/':
                if (inputValues.sublist(1).any((val) => val == 0)) {
                  error = 'تقسیم بر صفر';
                } else {
                  result = inputValues
                      .sublist(1)
                      .fold(inputValues[0], (prev, e) => prev / e);
                }
                break;
              default:
                // This default case makes the logic robust.
                error = 'عملگر ناشناخته';
                break;
            }
            if (error == null) {
              outputValues['result'] = result;
            }
          }
          break;
        case NodeType.output:
          final value = inputs['value'];
          if (value != null) {
            outputValues['value'] = value;
          }
          break;
        case NodeType.condition:
          break;
      }
    } catch (e) {
      error = 'خطا در محاسبه';
    }

    node.add(
        NodeStateComponent(outputValues: outputValues, errorMessage: error));
  }

  List<Entity> _topologicalSort(List<Entity> nodes, List<Entity> connections) {
    final inDegree = <EntityId, int>{};
    final graph = <EntityId, List<EntityId>>{};

    for (final node in nodes) {
      inDegree[node.id] = 0;
      graph[node.id] = [];
    }

    for (final connEntity in connections) {
      final conn = connEntity.get<ConnectionComponent>()!;
      if (graph.containsKey(conn.fromNodeId) &&
          inDegree.containsKey(conn.toNodeId)) {
        graph[conn.fromNodeId]!.add(conn.toNodeId);
        inDegree[conn.toNodeId] = (inDegree[conn.toNodeId] ?? 0) + 1;
      }
    }

    final queue = nodes.where((n) => inDegree[n.id] == 0).toList();
    final sorted = <Entity>[];

    int processedCount = 0;
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      sorted.add(node);
      processedCount++;

      if (graph[node.id] == null) continue;

      for (final neighborId in graph[node.id]!) {
        inDegree[neighborId] = inDegree[neighborId]! - 1;
        if (inDegree[neighborId] == 0) {
          final neighborNode =
              nodes.firstWhereOrNull((n) => n.id == neighborId);
          if (neighborNode != null) {
            queue.add(neighborNode);
          }
        }
      }
    }

    if (processedCount != nodes.length) {
      print(
          "Error: Cycle detected in the formula graph. Evaluation may be incorrect.");
    }

    return sorted;
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
