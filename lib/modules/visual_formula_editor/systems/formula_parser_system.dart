// FILE: lib/modules/visual_formula_editor/systems/formula_parser_system.dart
// (English comments for code clarity)
// MODIFIED v8.0: FINAL, ROBUST FIX for Persian variables. Implemented a
// variable mapping system. Persian phrases are now replaced with safe, temporary
// ASCII identifiers before parsing, and then mapped back to the original
// Persian for display. This is the definitive solution.

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
  // Maps sanitized variable names (e.g., __var0__) to their original display names (e.g., "عرض پارچه").
  final Map<String, String> _sanitizedToOriginal = {};

  FormulaParserSystem();

  /// Pre-processes the expression to handle multi-word and non-ASCII variables.
  String _sanitizeExpression(String expression) {
    _sanitizedToOriginal.clear();
    int varIndex = 0;
    // This regex finds sequences of non-operator, non-numeric, non-grouping characters.
    // It correctly captures multi-word Persian and English phrases.
    final variableRegex =
        RegExp(r'([a-zA-Z\u0600-\u06FF_][a-zA-Z0-9\u0600-\u06FF_\s]*)');

    return expression.replaceAllMapped(variableRegex, (match) {
      final originalPhrase = match.group(0)!.trim();
      // Ignore numbers that might be caught by the regex
      if (double.tryParse(originalPhrase) != null) {
        return originalPhrase;
      }
      // Generate a safe, temporary variable name
      final sanitized = '__var${varIndex++}__';
      _sanitizedToOriginal[sanitized] = originalPhrase;
      return sanitized;
    });
  }

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
      final sanitizedExpression = _sanitizeExpression(expression);
      final parsedExpression = Expression.parse(sanitizedExpression);
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

  List<Expression> _flattenExpression(
      BinaryExpression expression, String operator) {
    final List<Expression> operands = [];

    if (expression.left is BinaryExpression &&
        (expression.left as BinaryExpression).operator.toString() == operator) {
      operands.addAll(
          _flattenExpression(expression.left as BinaryExpression, operator));
    } else {
      operands.add(expression.left);
    }

    if (expression.right is BinaryExpression &&
        (expression.right as BinaryExpression).operator.toString() ==
            operator) {
      operands.addAll(
          _flattenExpression(expression.right as BinaryExpression, operator));
    } else {
      operands.add(expression.right);
    }
    return operands;
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
      final sanitizedName = expression.identifier.name;
      final displayName = _sanitizedToOriginal[sanitizedName] ?? sanitizedName;

      final node = createNodeFromType(NodeType.input, x, y);
      final nodeComp = node.get<NodeComponent>()!;
      nodeComp.data['inputId'] = sanitizedName;
      node.add(nodeComp.copyWith(label: displayName));
      entities.add(node);
      return node;
    } else if (expression is BinaryExpression) {
      final operator = expression.operator.toString();
      final operands = _flattenExpression(expression, operator);

      final operatorNode = createNodeFromType(NodeType.operator, x, y);
      final opComp = operatorNode.get<NodeComponent>()!;
      opComp.data['operator'] = operator;

      final newInputs = <NodePort>[];
      for (int i = 0; i < operands.length; i++) {
        final portId = 'in_$i';
        final portLabel = String.fromCharCode('A'.codeUnitAt(0) + i);
        newInputs.add(NodePort(id: portId, label: portLabel));

        final operandEntity = _parseNode(operands[i], depth + 1, entities);
        if (operandEntity != null) {
          final conn = Entity()
            ..add(ConnectionComponent(
                fromNodeId: operandEntity.id,
                fromPortId:
                    operandEntity.get<NodeComponent>()!.outputs.first.id,
                toNodeId: operatorNode.id,
                toPortId: portId))
            ..add(TagsComponent({'connection_component'}));
          entities.add(conn);
        }
      }

      final newPortIndex = newInputs.length;
      final newPortId = 'in_$newPortIndex';
      final newPortLabel =
          String.fromCharCode('A'.codeUnitAt(0) + newPortIndex);
      newInputs.add(NodePort(id: newPortId, label: newPortLabel));

      operatorNode.add(opComp.copyWith(label: operator, inputs: newInputs));
      entities.add(operatorNode);

      return operatorNode;
    }
    return null;
  }
}
