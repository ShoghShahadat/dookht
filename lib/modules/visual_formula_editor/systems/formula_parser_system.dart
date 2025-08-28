// FILE: lib/modules/visual_formula_editor/systems/formula_parser_system.dart
// (English comments for code clarity)
// MODIFIED v5.0: FINAL FIX - After creating an operator node from text,
// it now adds an extra empty input port, mirroring the behavior of the
// dynamic port system for a consistent user experience.

import 'package:expressions/expressions.dart';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// A system responsible for parsing a mathematical expression string and generating
/// a corresponding graph of Node and Connection entities with a proper layout.
class FormulaParserSystem {
  final double _xStep = 200;
  final double _yStep = 120;
  final Map<int, double> _yPositions = {};

  FormulaParserSystem();

  List<Entity> parse(String resultKey, String expression) {
    _yPositions.clear();
    final List<Entity> entities = [];

    final outputNode = createNodeFromType(NodeType.output, 800, 250);
    outputNode.get<NodeComponent>()!.data['resultKey'] = resultKey;
    entities.add(outputNode);

    if (expression.trim().isEmpty) {
      return entities;
    }

    try {
      final parsedExpression = Expression.parse(expression);
      final resultEntity = _parseNode(parsedExpression, 0, entities);

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
      debugPrint("[FormulaParserSystem] Handled parser error: $e");
    } catch (e) {
      debugPrint(
          "[FormulaParserSystem] Unexpected error parsing expression '$expression': $e");
    }
    return entities;
  }

  Entity? _parseNode(Expression expression, int depth, List<Entity> entities) {
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

      // **MAJOR FIX**: Add an extra empty input port to operator nodes,
      // just like the DynamicPortSystem does for visually created nodes.
      final currentOpComp = operatorNode.get<NodeComponent>()!;
      final newPortIndex = currentOpComp.inputs.length;
      final newPortId = 'in_$newPortIndex';
      final newPortLabel =
          String.fromCharCode('A'.codeUnitAt(0) + newPortIndex);
      final newInputs = List<NodePort>.from(currentOpComp.inputs)
        ..add(NodePort(id: newPortId, label: newPortLabel));

      operatorNode.add(currentOpComp.copyWith(inputs: newInputs));

      return operatorNode;
    }
    return null;
  }
}
