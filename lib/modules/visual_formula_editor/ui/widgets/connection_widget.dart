// FILE: lib/modules/visual_formula_editor/ui/widgets/connection_widget.dart
// (English comments for code clarity)
// This widget renders the interactive delete button for a selected connection.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

class ConnectionWidget extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId connId;
  final EditorCanvasComponent canvasState;

  const ConnectionWidget({
    super.key,
    required this.renderingSystem,
    required this.connId,
    required this.canvasState,
  });

  @override
  Widget build(BuildContext context) {
    final conn = renderingSystem.get<ConnectionComponent>(connId);
    if (conn == null) return const SizedBox.shrink();

    final fromNode = renderingSystem.get<NodeComponent>(conn.fromNodeId);
    final toNode = renderingSystem.get<NodeComponent>(conn.toNodeId);
    if (fromNode == null || toNode == null) return const SizedBox.shrink();

    final start = getPortPosition(fromNode, conn.fromPortId, true);
    final end = getPortPosition(toNode, conn.toPortId, false);
    if (start == null || end == null) return const SizedBox.shrink();

    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final isSelected = canvasState.selectedEntityId == connId;

    if (!isSelected) return const SizedBox.shrink();

    return Positioned(
      left: midPoint.dx - 12,
      top: midPoint.dy - 12,
      child: GestureDetector(
        onTap: () =>
            renderingSystem.manager?.send(DeleteConnectionEvent(connId)),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
              color: Colors.redAccent, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
