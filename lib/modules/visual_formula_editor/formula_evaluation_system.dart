// FILE: lib/modules/visual_formula_editor/formula_evaluation_system.dart
// (English comments for code clarity)
// FIX v1.1: Refactored the system to be event-driven instead of running every frame.
// This is the primary fix for the infinite loop/hang issue.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

/// The brain of the visual editor. Evaluates the node graph in response to events.
class FormulaEvaluationSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen for the specific event to trigger a recalculation.
    listen<RecalculateGraphEvent>(_onRecalculate);
  }

  /// This method is now the core logic, triggered only when needed.
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

    // 1. Clear previous states
    for (final node in nodes) {
      // Only remove the state if it exists to avoid unnecessary notifications.
      if (node.has<NodeStateComponent>()) {
        node.remove<NodeStateComponent>();
      }
    }

    // 2. Topological sort to get execution order
    final sortedNodes = _topologicalSort(nodes, connections);

    // 3. Evaluate each node in order
    for (final node in sortedNodes) {
      _evaluateNode(node, canvasState.previewInputValues);
    }
  }

  void _evaluateNode(Entity node, Map<String, double> previewInputs) {
    final nodeComp = node.get<NodeComponent>()!;
    final inputs = <String, dynamic>{};
    String? error;

    // Gather inputs from connected nodes
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
          final a = inputs['a'] as num?;
          final b = inputs['b'] as num?;
          if (a == null || b == null) {
            error = 'ورودی‌ها متصل نیستند';
          } else {
            switch (nodeComp.data['operator']) {
              case '+':
                outputValues['result'] = a + b;
                break;
              case '-':
                outputValues['result'] = a - b;
                break;
              case '*':
                outputValues['result'] = a * b;
                break;
              case '/':
                // Avoid division by zero
                if (b == 0) {
                  error = 'تقسیم بر صفر';
                } else {
                  outputValues['result'] = a / b;
                }
                break;
            }
          }
          break;
        case NodeType.output:
        case NodeType.condition:
          // TODO: Implement later
          break;
      }
    } catch (e) {
      error = 'خطا در محاسبه';
    }

    node.add(
        NodeStateComponent(outputValues: outputValues, errorMessage: error));
  }

  List<Entity> _topologicalSort(List<Entity> nodes, List<Entity> connections) {
    // Simple implementation, assumes no cyclic dependencies for now.
    // A real implementation would need cycle detection.
    final inDegree = <EntityId, int>{};
    final graph = <EntityId, List<EntityId>>{};

    for (final node in nodes) {
      inDegree[node.id] = 0;
      graph[node.id] = [];
    }

    for (final connEntity in connections) {
      final conn = connEntity.get<ConnectionComponent>()!;
      graph[conn.fromNodeId]!.add(conn.toNodeId);
      inDegree[conn.toNodeId] = (inDegree[conn.toNodeId] ?? 0) + 1;
    }

    final queue = nodes.where((n) => inDegree[n.id] == 0).toList();
    final sorted = <Entity>[];

    int processedCount = 0;
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      sorted.add(node);
      processedCount++;

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
      // This indicates a cycle in the graph.
      // A more robust implementation would identify and report the cycle.
      print(
          "Error: Cycle detected in the formula graph. Evaluation may be incorrect.");
    }

    return sorted;
  }

  @override
  bool matches(Entity entity) => false; // Now purely event-driven

  @override
  void update(Entity entity, double dt) {} // No longer used
}
