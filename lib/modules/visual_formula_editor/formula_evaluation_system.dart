// FILE: lib/modules/visual_formula_editor/formula_evaluation_system.dart
// (English comments for code clarity)

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';

/// The brain of the visual editor. Evaluates the node graph in real-time.
class FormulaEvaluationSystem extends System {
  @override
  bool matches(Entity entity) {
    // This system runs when the canvas state changes, specifically the preview values.
    return entity.has<EditorCanvasComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final canvasState = entity.get<EditorCanvasComponent>()!;
    final nodes =
        world.entities.values.where((e) => e.has<NodeComponent>()).toList();
    final connections = world.entities.values
        .where((e) => e.has<ConnectionComponent>())
        .toList();

    // 1. Clear previous states
    for (final node in nodes) {
      node.remove<NodeStateComponent>();
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
                outputValues['result'] = a / b;
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

    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      sorted.add(node);

      for (final neighborId in graph[node.id]!) {
        inDegree[neighborId] = inDegree[neighborId]! - 1;
        if (inDegree[neighborId] == 0) {
          queue.add(nodes.firstWhere((n) => n.id == neighborId));
        }
      }
    }
    return sorted;
  }
}
