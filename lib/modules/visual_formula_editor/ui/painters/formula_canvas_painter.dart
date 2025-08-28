// FILE: lib/modules/visual_formula_editor/ui/painters/formula_canvas_painter.dart
// (English comments for code clarity)
// REFACTORED v1.1: The painter is now only responsible for drawing connections.
// Nodes are rendered as separate widgets for better interactivity.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// The CustomPainter that will render our entire formula graph.
class FormulaCanvasPainter extends CustomPainter {
  final FlutterRenderingSystem renderingSystem;
  final List<EntityId> connectionIds;
  final EditorCanvasComponent? canvasState;

  FormulaCanvasPainter({
    required this.renderingSystem,
    required this.connectionIds,
    this.canvasState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final transformMatrix = Matrix4.identity()
      ..translate(canvasState?.panX ?? 0.0, canvasState?.panY ?? 0.0)
      ..scale(canvasState?.zoom ?? 1.0);

    canvas.save();
    canvas.transform(transformMatrix.storage);

    // Draw connections first so they appear behind nodes
    for (final connectionId in connectionIds) {
      final connComp = renderingSystem.get<ConnectionComponent>(connectionId);
      if (connComp != null) {
        _drawConnection(canvas, connectionId, connComp);
      }
    }

    // Draw the connection being drafted by the user
    _drawDraftConnection(canvas);

    canvas.restore();
  }

  void _drawConnection(
      Canvas canvas, EntityId connId, ConnectionComponent conn) {
    final fromNode = renderingSystem.get<NodeComponent>(conn.fromNodeId);
    final toNode = renderingSystem.get<NodeComponent>(conn.toNodeId);
    if (fromNode == null || toNode == null) return;

    final startPoint = getPortPosition(fromNode, conn.fromPortId, true);
    final endPoint = getPortPosition(toNode, conn.toPortId, false);
    if (startPoint == null || endPoint == null) return;

    final isSelected = canvasState?.selectedEntityId == connId;

    final paint = Paint()
      ..color = isSelected ? Colors.amber : Colors.white
      ..strokeWidth = isSelected ? 4.0 : 2.0
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

      final startPoint =
          getPortPosition(startNode, canvasState!.connectionStartPortId!, true);
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

  @override
  bool shouldRepaint(covariant FormulaCanvasPainter oldDelegate) {
    // The painter should repaint whenever the animation notifier from the
    // rendering system fires, which we've connected in the main widget.
    return true;
  }
}
