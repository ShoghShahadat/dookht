// FILE: lib/modules/visual_formula_editor/systems/graph_generator_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: Rewritten to be fully recursive, correctly handling operator
// precedence by adding parentheses around binary expression results.

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

    // Start the recursive generation from the output node's input.
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

        if (inputs.isEmpty) {
          result = '0';
        } else if (inputs.length == 1) {
          result = inputs.first;
        } else {
          // Correctly join with parentheses to respect operator precedence
          result = "(${inputs.join(' $operator ')})";
        }
        break;
      case NodeType.output:
        // The output node's value is the expression of its single input.
        final inputs = _getConnectedInputExpressions(nodeId);
        result = inputs.firstOrNull ?? '';
        break;
      case NodeType.condition:
        // This is a simplified representation. A full implementation would
        // require a more complex language than standard math expressions.
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
        result = "($a $op $b ? $pass : 0)"; // Ternary operator representation
        break;
    }

    _memo[nodeId] = result;
    return result;
  }

  List<String> _getConnectedInputExpressions(EntityId nodeId,
      {String? portId}) {
    final node = _world.entities[nodeId];
    if (node == null) return [];

    final nodeComp = node.get<NodeComponent>()!;
    final targetPorts = portId != null
        ? nodeComp.inputs.where((p) => p.id == portId)
        : nodeComp.inputs;

    final expressions = <String>[];
    for (final port in targetPorts) {
      final connection = _world.entities.values.firstWhereOrNull((e) {
        final c = e.get<ConnectionComponent>();
        return c != null && c.toNodeId == nodeId && c.toPortId == port.id;
      });

      if (connection != null) {
        expressions.add(_generateForNode(
            connection.get<ConnectionComponent>()!.fromNodeId));
      }
    }
    return expressions;
  }
}
