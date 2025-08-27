// FILE: lib/modules/visual_formula_editor/ui/painters/formula_canvas_painter.dart
// (English comments for code clarity)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';

/// The CustomPainter that will render our entire formula graph.
class FormulaCanvasPainter extends CustomPainter {
  final FlutterRenderingSystem renderingSystem;
  final List<EntityId> nodeIds;
  final List<EntityId> connectionIds;
  final EditorCanvasComponent? canvasState;

  FormulaCanvasPainter({
    required this.renderingSystem,
    required this.nodeIds,
    required this.connectionIds,
    this.canvasState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.2);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Draw connections first so they appear behind nodes
    for (final connectionId in connectionIds) {
      final connComp = renderingSystem.get<ConnectionComponent>(connectionId);
      if (connComp != null) {
        _drawConnection(canvas, connComp);
      }
    }

    // Draw the connection being drafted by the user
    _drawDraftConnection(canvas);

    // Draw each node on top of the connections
    for (final nodeId in nodeIds) {
      final nodeComp = renderingSystem.get<NodeComponent>(nodeId);
      final nodeState = renderingSystem.get<NodeStateComponent>(nodeId);
      if (nodeComp != null) {
        _drawNode(canvas, nodeId, nodeComp, nodeState);
      }
    }
  }

  void _drawNode(Canvas canvas, EntityId nodeId, NodeComponent node,
      NodeStateComponent? state) {
    final pos = node.position;
    final rect = Rect.fromLTWH(pos.x, pos.y, pos.width, pos.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    final nodePaint = Paint()..color = _getColorForNodeType(node.type);
    canvas.drawRRect(rrect, nodePaint);

    String displayValue = '';
    if (state?.errorMessage != null) {
      displayValue = state!.errorMessage!;
    } else if (state?.outputValues.isNotEmpty ?? false) {
      final value = state!.outputValues.values.first;
      if (value is num) {
        displayValue = value.toStringAsFixed(2);
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(children: [
        TextSpan(
            text: node.label,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        if (displayValue.isNotEmpty)
          TextSpan(
              text: '\n$displayValue',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 14)),
      ]),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
    textPainter.layout(minWidth: 0, maxWidth: pos.width - 16);
    final offset = Offset(rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);

    _drawPorts(canvas, nodeId, node);
  }

  void _drawPorts(Canvas canvas, EntityId nodeId, NodeComponent node) {
    final pos = node.position;
    final portPaint = Paint()..color = Colors.white.withOpacity(0.7);
    final portPaintHighlight = Paint()..color = Colors.amber;

    // Outputs
    for (var i = 0; i < node.outputs.length; i++) {
      final y = pos.y + (pos.height / (node.outputs.length + 1)) * (i + 1);
      final isBeingConnected = canvasState?.connectionStartNodeId == nodeId &&
          canvasState?.connectionStartPortId == node.outputs[i].id;
      canvas.drawCircle(Offset(pos.x + pos.width, y), 8.0,
          isBeingConnected ? portPaintHighlight : portPaint);
    }
    // Inputs
    for (var i = 0; i < node.inputs.length; i++) {
      final y = pos.y + (pos.height / (node.inputs.length + 1)) * (i + 1);
      canvas.drawCircle(Offset(pos.x, y), 8.0, portPaint);
    }
  }

  void _drawConnection(Canvas canvas, ConnectionComponent conn) {
    final fromNode = renderingSystem.get<NodeComponent>(conn.fromNodeId);
    final toNode = renderingSystem.get<NodeComponent>(conn.toNodeId);
    if (fromNode == null || toNode == null) return;

    final startPoint = _getPortPosition(fromNode, conn.fromPortId, true);
    final endPoint = _getPortPosition(toNode, conn.toPortId, false);
    if (startPoint == null || endPoint == null) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(startPoint.dx + 50, startPoint.dy, endPoint.dx - 50,
        endPoint.dy, endPoint.dx, endPoint.dy);
    canvas.drawPath(path, paint);
  }

  void _drawDraftConnection(Canvas canvas) {
    if (canvasState?.connectionStartNodeId != null) {
      final startNode = renderingSystem
          .get<NodeComponent>(canvasState!.connectionStartNodeId!);
      if (startNode == null) return;

      final startPoint = _getPortPosition(
          startNode, canvasState!.connectionStartPortId!, true);
      final endPoint = Offset(
          canvasState!.connectionDraftX!, canvasState!.connectionDraftY!);
      if (startPoint == null) return;

      final paint = Paint()
        ..color = Colors.amber
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      path.cubicTo(startPoint.dx + 50, startPoint.dy, endPoint.dx - 50,
          endPoint.dy, endPoint.dx, endPoint.dy);
      canvas.drawPath(path, paint);
    }
  }

  Offset? _getPortPosition(NodeComponent node, String portId, bool isOutput) {
    final pos = node.position;
    final ports = isOutput ? node.outputs : node.inputs;
    final index = ports.indexWhere((p) => p.id == portId);
    if (index == -1) return null;

    final x = isOutput ? pos.x + pos.width : pos.x;
    final y = pos.y + (pos.height / (ports.length + 1)) * (index + 1);
    return Offset(x, y);
  }

  Color _getColorForNodeType(NodeType type) {
    switch (type) {
      case NodeType.input:
        return Colors.blue.shade700.withOpacity(0.8);
      case NodeType.constant:
        return Colors.grey.shade700.withOpacity(0.8);
      case NodeType.operator:
        return Colors.orange.shade800.withOpacity(0.8);
      case NodeType.output:
        return Colors.green.shade700.withOpacity(0.8);
      case NodeType.condition:
        return Colors.purple.shade700.withOpacity(0.8);
    }
  }

  @override
  bool shouldRepaint(covariant FormulaCanvasPainter oldDelegate) {
    // For performance, we should do a proper comparison, but for now,
    // always repainting is fine as the data changes frequently.
    return true;
  }
}
