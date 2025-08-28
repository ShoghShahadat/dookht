// FILE: lib/modules/visual_formula_editor/systems/formula_parser_system.dart
// (English comments for code clarity)
// NEW FILE: Implements the logic to parse an expression string into a visual graph of entities.

import 'package:expressions/expressions.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// A system responsible for parsing a mathematical expression string and generating
/// a corresponding graph of Node and Connection entities.
class FormulaParserSystem {
  final NexusWorld _world;
  final List<DynamicVariable> _variables;
  double _currentX = 600; // Start laying out nodes from the right
  final double _yStep = 120;
  final double _xStep = 200;

  FormulaParserSystem(this._world, this._variables);

  List<Entity> parse(String resultKey, String expression) {
    _currentX = 600;
    final List<Entity> entities = [];
    try {
      final parsedExpression = Expression.parse(expression);

      // Create the final output node
      final outputNode =
          createNodeFromType(NodeType.output, _currentX + _xStep, 250)
            ..get<NodeComponent>()!.data['resultKey'] = resultKey;
      entities.add(outputNode);

      // Recursively parse the expression tree
      final resultEntity = _parseNode(parsedExpression, 250, entities);

      // Connect the result of the expression to the output node
      if (resultEntity != null) {
        final connection = Entity()
          ..add(ConnectionComponent(
            fromNodeId: resultEntity.id,
            fromPortId: resultEntity.get<NodeComponent>()!.outputs.first.id,
            toNodeId: outputNode.id,
            toPortId: outputNode.get<NodeComponent>()!.inputs.first.id,
          ));
        entities.add(connection);
      }
    } catch (e) {
      print("[FormulaParserSystem] Error parsing expression '$expression': $e");
      // Return an empty list or a default error node if parsing fails
    }
    return entities;
  }

  Entity? _parseNode(Expression expression, double y, List<Entity> entities) {
    _currentX -= _xStep;

    if (expression is Literal) {
      final value = expression.value;
      if (value is num) {
        final node = createNodeFromType(NodeType.constant, _currentX, y);
        node.get<NodeComponent>()!.data['value'] = value.toDouble();
        entities.add(node);
        return node;
      }
    } else if (expression is Variable) {
      final varName = expression.identifier.name;
      // Check if it's a measurement or a dynamic variable
      final isVariable = _variables.any((v) => v.key == varName);
      if (isVariable) {
        final node = createNodeFromType(NodeType.input, _currentX, y);
        final nodeComp = node.get<NodeComponent>()!;
        nodeComp.data['inputId'] = varName;
        node.add(nodeComp.copyWith(label: varName));
        entities.add(node);
        return node;
      } else {
        // Assuming it's a measurement input
        final node = createNodeFromType(NodeType.input, _currentX, y);
        final nodeComp = node.get<NodeComponent>()!;
        nodeComp.data['inputId'] = varName;
        node.add(nodeComp.copyWith(label: varName));
        entities.add(node);
        return node;
      }
    } else if (expression is BinaryExpression) {
      final operatorNode = createNodeFromType(NodeType.operator, _currentX, y);
      final opComp = operatorNode.get<NodeComponent>()!;
      opComp.data['operator'] = expression.operator.toString();
      operatorNode.add(opComp.copyWith(label: expression.operator.toString()));
      entities.add(operatorNode);

      final leftEntity =
          _parseNode(expression.left, y - (_yStep / 2), entities);
      final rightEntity =
          _parseNode(expression.right, y + (_yStep / 2), entities);

      if (leftEntity != null) {
        final conn = Entity()
          ..add(ConnectionComponent(
              fromNodeId: leftEntity.id,
              fromPortId: leftEntity.get<NodeComponent>()!.outputs.first.id,
              toNodeId: operatorNode.id,
              toPortId: 'in_0'));
        entities.add(conn);
      }
      if (rightEntity != null) {
        final conn = Entity()
          ..add(ConnectionComponent(
              fromNodeId: rightEntity.id,
              fromPortId: rightEntity.get<NodeComponent>()!.outputs.first.id,
              toNodeId: operatorNode.id,
              toPortId: 'in_1'));
        entities.add(conn);
      }
      return operatorNode;
    }
    // Handle other expression types like UnaryExpression if needed
    return null;
  }
}
