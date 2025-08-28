// FILE: lib/modules/visual_formula_editor/ui/widgets/interactive_canvas_layer.dart
// (English comments for code clarity)
// FIX v2.0: Added `behavior: HitTestBehavior.opaque` to the GestureDetector.
// This is a CRITICAL fix that makes the entire canvas area interactive,
// allowing panning in empty space and interaction with newly added nodes.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/painters/formula_canvas_painter.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/connection_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/node_widget.dart';

class InteractiveCanvasLayer extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;
  final List<EntityId> nodeIds;
  final List<EntityId> connectionIds;
  final EditorCanvasComponent canvasState;

  const InteractiveCanvasLayer({
    super.key,
    required this.renderingSystem,
    required this.nodeIds,
    required this.connectionIds,
    required this.canvasState,
  });

  @override
  Widget build(BuildContext context) {
    final transformMatrix = Matrix4.identity()
      ..translate(canvasState.panX, canvasState.panY)
      ..scale(canvasState.zoom);

    return GestureDetector(
      // *** BUG FIX: Make the entire area interactive ***
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        renderingSystem.manager?.send(CanvasScaleStartEvent(
          focalX: details.localFocalPoint.dx,
          focalY: details.localFocalPoint.dy,
        ));
      },
      onScaleUpdate: (details) {
        renderingSystem.manager?.send(CanvasScaleUpdateEvent(
          focalX: details.localFocalPoint.dx,
          focalY: details.localFocalPoint.dy,
          scale: details.scale,
          deltaX: details.focalPointDelta.dx,
          deltaY: details.focalPointDelta.dy,
        ));
      },
      onScaleEnd: (details) {
        renderingSystem.manager?.send(CanvasScaleEndEvent());
      },
      onTapUp: (details) {
        renderingSystem.manager?.send(CanvasTapUpEvent(
            localX: details.localPosition.dx,
            localY: details.localPosition.dy));
      },
      onLongPressStart: (details) {
        renderingSystem.manager?.send(CanvasLongPressStartEvent(
            localX: details.localPosition.dx,
            localY: details.localPosition.dy));
      },
      child: Transform(
        transform: transformMatrix,
        alignment: Alignment.topLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              painter: FormulaCanvasPainter(
                renderingSystem: renderingSystem,
                connectionIds: connectionIds,
                canvasState: canvasState,
              ),
              // Ensure the painter covers the whole area to be interactive
              child: const SizedBox.expand(),
            ),
            ...nodeIds.map((id) => NodeWidget(
                renderingSystem: renderingSystem,
                nodeId: id,
                canvasState: canvasState)),
            ...connectionIds.map((id) => ConnectionWidget(
                renderingSystem: renderingSystem,
                connId: id,
                canvasState: canvasState)),
          ],
        ),
      ),
    );
  }
}
