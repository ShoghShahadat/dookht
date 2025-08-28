// FILE: lib/modules/visual_formula_editor/ui/widgets/context_menu_widget.dart
// (English comments for code clarity)
// NEW FILE: This widget is responsible for rendering the context menu (e.g., delete button)
// for a node that has been long-pressed.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

class ContextMenuWidget extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;
  final EditorCanvasComponent canvasState;

  const ContextMenuWidget({
    super.key,
    required this.renderingSystem,
    required this.canvasState,
  });

  @override
  Widget build(BuildContext context) {
    final nodeId = canvasState.contextMenuNodeId;
    if (nodeId == null) {
      return const SizedBox.shrink();
    }

    final node = renderingSystem.get<NodeComponent>(nodeId);
    if (node == null) {
      return const SizedBox.shrink();
    }

    // Calculate the position for the menu. We'll place it above the node.
    final menuX = node.position.x + node.position.width / 2;
    final menuY = node.position.y - 40; // 40 pixels above the node

    // Apply the same canvas transform to the menu's position
    final transformMatrix = Matrix4.identity()
      ..translate(canvasState.panX, canvasState.panY)
      ..scale(canvasState.zoom);

    final transformedPoint =
        MatrixUtils.transformPoint(transformMatrix, Offset(menuX, menuY));

    return Positioned(
      left: transformedPoint.dx - 25, // Center the button
      top: transformedPoint.dy - 25, // Center the button
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          icon: const Icon(Icons.delete_forever,
              color: Colors.redAccent, size: 30),
          tooltip: 'حذف نود',
          onPressed: () {
            renderingSystem.manager?.send(DeleteNodeEvent(nodeId));
            renderingSystem.manager?.send(HideContextMenuEvent());
          },
        ),
      ),
    );
  }
}
