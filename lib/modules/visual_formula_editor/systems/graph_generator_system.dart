// FILE: lib/modules/visual_formula_editor/systems/graph_generator_system.dart
// (English comments for code clarity)
// NEW FILE: Implements the logic to generate an expression string from a visual graph.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';

/// A system responsible for traversing a node graph and generating a
/// corresponding mathematical expression string.
class GraphGeneratorSystem {
  final NexusWorld _world;
  final Map<EntityId, String> _memo = {}; // Memoization for performance

  GraphGeneratorSystem(this._world);

  String generate() {
    _memo.clear();
    final outputNode = _world.entities.values.firstWhereOrNull(
        (e) => e.get<NodeComponent>()?.type == NodeType.output);

    if (outputNode == null) {
      return ""; // No output node, no expression
    }

    return _generateForNode(outputNode.id);
  }

  String _generateForNode(EntityId nodeId) {
    if (_memo.containsKey(nodeId)) {
      return _memo[nodeId]!;
    }

    final node = _world.entities[nodeId];
    final nodeComp = node?.get<NodeComponent>();
    if (nodeComp == null) return '?';

    String result;
    switch (nodeComp.type) {
      case NodeType.input:
        result = nodeComp.data['inputId'] as String? ?? '?';
        break;
      case NodeType.constant:
        result = (nodeComp.data['value'] as num? ?? 0).toString();
        break;
      case NodeType.operator:
        final operator = nodeComp.data['operator'] as String? ?? '+';
        final inputs = _getConnectedInputExpressions(nodeId);
        if (inputs.length < 2) {
          result = '?'; // Not enough inputs for an operator
        } else {
          result = "(${inputs.join(' $operator ')})";
        }
        break;
      case NodeType.output:
        final inputs = _getConnectedInputExpressions(nodeId);
        result = inputs.firstOrNull ?? '';
        break;
      case NodeType.condition:
        final a =
            _getConnectedInputExpressions(nodeId, portId: 'in_a').firstOrNull ??
                '?';
        final b =
            _getConnectedInputExpressions(nodeId, portId: 'in_b').firstOrNull ??
                '?';
        final pass = _getConnectedInputExpressions(nodeId, portId: 'pass_value')
                .firstOrNull ??
            '?';
        final op = nodeComp.data['operator'] as String? ?? '==';
        result = "if ($a $op $b) then $pass"; // Simplified representation
        break;
    }

    _memo[nodeId] = result;
    return result;
  }

  List<String> _getConnectedInputExpressions(EntityId nodeId,
      {String? portId}) {
    final connections = _world.entities.values.whereType<Entity>().where((e) {
      final c = e.get<ConnectionComponent>();
      if (c == null || c.toNodeId != nodeId) return false;
      return portId == null ? true : c.toPortId == portId;
    });

    return connections
        .map((conn) =>
            _generateForNode(conn.get<ConnectionComponent>()!.fromNodeId))
        .toList();
  }
}
