// FILE: lib/modules/visual_formula_editor/systems/formula_parser_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: Rewritten with a more robust, recursive layout algorithm to
// prevent nodes from overlapping in complex expressions.

import 'package:expressions/expressions.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// A system responsible for parsing a mathematical expression string and generating
/// a corresponding graph of Node and Connection entities with a proper layout.
class FormulaParserSystem {
  final NexusWorld _world;
  final List<DynamicVariable> _variables;
  final double _xStep = 200;
  final double _yStep = 120;

  // A map to track the y-position for each level of the tree to avoid overlaps
  final Map<int, double> _yPositions = {};

  FormulaParserSystem(this._world, this._variables);

  List<Entity> parse(String resultKey, String expression) {
    _yPositions.clear();
    final List<Entity> entities = [];
    if (expression.trim().isEmpty) {
      // If expression is empty, just create an output node
      final outputNode = createNodeFromType(NodeType.output, 800, 250)
        ..get<NodeComponent>()!.data['resultKey'] = resultKey;
      entities.add(outputNode);
      return entities;
    }

    try {
      final parsedExpression = Expression.parse(expression);

      // Create the final output node
      final outputNode = createNodeFromType(NodeType.output, 800, 250)
        ..get<NodeComponent>()!.data['resultKey'] = resultKey;
      entities.add(outputNode);

      // Recursively parse the expression tree, starting at depth 0
      final resultEntity = _parseNode(parsedExpression, 0, entities);

      // Connect the result of the expression to the output node
      if (resultEntity != null) {
        final connection = Entity()
          ..add(ConnectionComponent(
            fromNodeId: resultEntity.id,
            fromPortId: resultEntity.get<NodeComponent>()!.outputs.first.id,
            toNodeId: outputNode.id,
            toPortId: outputNode.get<NodeComponent>()!.inputs.first.id,
          ))
          ..add(TagsComponent({'connection_component'}));
        entities.add(connection);
      }
    } catch (e) {
      print("[FormulaParserSystem] Error parsing expression '$expression': $e");
      // Return just the output node if parsing fails
      final outputNode = createNodeFromType(NodeType.output, 800, 250)
        ..get<NodeComponent>()!.data['resultKey'] = resultKey;
      entities.add(outputNode);
    }
    return entities;
  }

  /// Recursively parses an expression node and lays out the graph.
  Entity? _parseNode(Expression expression, int depth, List<Entity> entities) {
    // Calculate position for the current node
    final x = 600 - (depth * _xStep);
    final y = _yPositions.update(depth, (value) => value + _yStep,
        ifAbsent: () => 100.0);

    if (expression is Literal) {
      final value = expression.value;
      if (value is num) {
        final node = createNodeFromType(NodeType.constant, x, y);
        node.get<NodeComponent>()!.data['value'] = value.toDouble();
        entities.add(node);
        return node;
      }
    } else if (expression is Variable) {
      final varName = expression.identifier.name;
      final node = createNodeFromType(NodeType.input, x, y);
      final nodeComp = node.get<NodeComponent>()!;
      nodeComp.data['inputId'] = varName;
      node.add(nodeComp.copyWith(label: varName));
      entities.add(node);
      return node;
    } else if (expression is BinaryExpression) {
      final operatorNode = createNodeFromType(NodeType.operator, x, y);
      final opComp = operatorNode.get<NodeComponent>()!;
      opComp.data['operator'] = expression.operator.toString();
      operatorNode.add(opComp.copyWith(label: expression.operator.toString()));
      entities.add(operatorNode);

      // Recursively parse children at the next depth level
      final leftEntity = _parseNode(expression.left, depth + 1, entities);
      final rightEntity = _parseNode(expression.right, depth + 1, entities);

      if (leftEntity != null) {
        final conn = Entity()
          ..add(ConnectionComponent(
              fromNodeId: leftEntity.id,
              fromPortId: leftEntity.get<NodeComponent>()!.outputs.first.id,
              toNodeId: operatorNode.id,
              toPortId: 'in_0'))
          ..add(TagsComponent({'connection_component'}));
        entities.add(conn);
      }
      if (rightEntity != null) {
        final conn = Entity()
          ..add(ConnectionComponent(
              fromNodeId: rightEntity.id,
              fromPortId: rightEntity.get<NodeComponent>()!.outputs.first.id,
              toNodeId: operatorNode.id,
              toPortId: 'in_1'))
          ..add(TagsComponent({'connection_component'}));
        entities.add(conn);
      }
      return operatorNode;
    }
    // Handle other expression types like UnaryExpression if needed
    return null;
  }
}
