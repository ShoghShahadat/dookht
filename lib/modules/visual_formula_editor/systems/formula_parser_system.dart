// FILE: lib/modules/visual_formula_editor/systems/formula_parser_system.dart
// (English comments for code clarity)
// MODIFIED v4.0: MAJOR FIX - Changed the catch clause to a more generic
// 'on Exception' to resolve the 'non_type_in_catch_clause' error.
// Also removed unused private fields '_world' and '_variables'.

import 'package:expressions/expressions.dart';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// A system responsible for parsing a mathematical expression string and generating
/// a corresponding graph of Node and Connection entities with a proper layout.
class FormulaParserSystem {
  // Unused fields removed to fix analyzer warnings.
  final double _xStep = 200;
  final double _yStep = 120;

  // A map to track the y-position for each level of the tree to avoid overlaps
  final Map<int, double> _yPositions = {};

  // Constructor no longer needs unused parameters.
  FormulaParserSystem();

  List<Entity> parse(String resultKey, String expression) {
    _yPositions.clear();
    final List<Entity> entities = [];

    // Always create the final output node first
    final outputNode = createNodeFromType(NodeType.output, 800, 250);
    outputNode.get<NodeComponent>()!.data['resultKey'] = resultKey;
    entities.add(outputNode);

    if (expression.trim().isEmpty) {
      return entities; // Return just the output node if expression is empty
    }

    try {
      final parsedExpression = Expression.parse(expression);

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
    } on Exception catch (e) {
      // **MAJOR FIX**: Using a more generic 'Exception' type to catch all
      // possible parsing errors robustly.
      debugPrint("[FormulaParserSystem] Handled parser error: $e");
    } catch (e) {
      debugPrint(
          "[FormulaParserSystem] Unexpected error parsing expression '$expression': $e");
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
