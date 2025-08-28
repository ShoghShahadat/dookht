// FILE: lib/modules/visual_formula_editor/ui/widgets/visual_formula_editor_widget.dart
// (English comments for code clarity)
// FIX v1.5: Re-added the onLongPressStart gesture handler to trigger the context menu.

import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/painters/formula_canvas_painter.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/preview_panel_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/toolbar_widget.dart';
import '../../../ui/rendering_system.dart';

/// The main stateful widget for the visual editor screen.
class VisualFormulaEditorWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId methodId;
  final EntityId editorEntityId;

  const VisualFormulaEditorWidget({
    super.key,
    required this.renderingSystem,
    required this.methodId,
    required this.editorEntityId,
  });

  @override
  State<VisualFormulaEditorWidget> createState() =>
      _VisualFormulaEditorWidgetState();
}

class _VisualFormulaEditorWidgetState extends State<VisualFormulaEditorWidget> {
  Color _getTextColor() {
    final rs = widget.renderingSystem;
    final themeManagerId = rs.getAllIdsWithTag('theme_manager').firstOrNull;
    if (themeManagerId == null) return Colors.white;
    final themeComp = rs.get<ThemeComponent>(themeManagerId);
    return Color(themeComp?.properties['textColor'] as int? ?? 0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.renderingSystem;
    final method = rs.get<PatternMethodComponent>(widget.methodId);
    if (method == null) {
      return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Method not found!')));
    }
    final textColor = _getTextColor();

    final nodeIds = rs.getAllIdsWithTag('node_component');
    final connectionIds = rs.getAllIdsWithTag('connection_component');

    final allNotifiers = <Listenable>[
      rs.getNotifier(widget.editorEntityId),
      ...nodeIds.map((id) => rs.getNotifier(id)),
      ...connectionIds.map((id) => rs.getNotifier(id)),
    ];
    final mergedListenable = Listenable.merge(allNotifiers);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('طراحی گرافیکی: ${method.name}',
            style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => rs.manager?.send(ShowMethodManagementEvent()),
        ),
      ),
      body: AnimatedBuilder(
        animation: mergedListenable,
        builder: (context, _) {
          final canvasState =
              rs.get<EditorCanvasComponent>(widget.editorEntityId);

          Offset? contextMenuScreenPos;
          if (canvasState?.contextMenuX != null &&
              canvasState?.contextMenuY != null &&
              canvasState?.zoom != null) {
            contextMenuScreenPos = Offset(
                canvasState!.contextMenuX! * canvasState.zoom +
                    canvasState.panX,
                canvasState.contextMenuY! * canvasState.zoom +
                    canvasState.panY);
          }

          return Stack(
            children: [
              SizedBox.expand(
                child: GestureDetector(
                  // Pan & Zoom
                  onScaleStart: (details) {
                    rs.manager?.send(CanvasScaleStartEvent(
                      focalX: details.localFocalPoint.dx,
                      focalY: details.localFocalPoint.dy,
                    ));
                  },
                  onScaleUpdate: (details) {
                    rs.manager?.send(CanvasScaleUpdateEvent(
                      focalX: details.localFocalPoint.dx,
                      focalY: details.localFocalPoint.dy,
                      scale: details.scale,
                    ));
                  },
                  onScaleEnd: (details) {
                    rs.manager?.send(CanvasScaleEndEvent());
                  },

                  // Discrete Tap
                  onTapUp: (details) {
                    final canvasState =
                        rs.get<EditorCanvasComponent>(widget.editorEntityId);
                    if (canvasState == null) return;
                    final canvasX =
                        (details.localPosition.dx - canvasState.panX) /
                            canvasState.zoom;
                    final canvasY =
                        (details.localPosition.dy - canvasState.panY) /
                            canvasState.zoom;
                    rs.manager?.send(
                        CanvasTapUpEvent(localX: canvasX, localY: canvasY));
                  },

                  // Dragging and Connecting
                  onPanStart: (details) {
                    rs.manager?.send(CanvasPanStartEvent(
                        localX: details.localPosition.dx,
                        localY: details.localPosition.dy));
                  },
                  onPanUpdate: (details) {
                    rs.manager?.send(CanvasPanUpdateEvent(
                        deltaX: details.delta.dx,
                        deltaY: details.delta.dy,
                        localX: details.localPosition.dx,
                        localY: details.localPosition.dy));
                  },
                  onPanEnd: (details) {
                    rs.manager?.send(CanvasPanEndEvent(
                      localX: details.globalPosition.dx,
                      localY: details.globalPosition.dy,
                    ));
                  },

                  // FIX: Re-added LongPress for context menu
                  onLongPressStart: (details) {
                    rs.manager?.send(CanvasLongPressStartEvent(
                        localX: details.localPosition.dx,
                        localY: details.localPosition.dy));
                  },

                  child: CustomPaint(
                    painter: FormulaCanvasPainter(
                      renderingSystem: rs,
                      nodeIds: nodeIds,
                      connectionIds: connectionIds,
                      canvasState: canvasState,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              ToolbarWidget(renderingSystem: rs),
              PreviewPanelWidget(
                renderingSystem: rs,
                nodeIds: nodeIds,
                canvasState: canvasState,
                textColor: textColor,
              ),
              if (canvasState?.contextMenuNodeId != null &&
                  contextMenuScreenPos != null)
                _buildContextMenu(rs, canvasState!, contextMenuScreenPos),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContextMenu(FlutterRenderingSystem rs,
      EditorCanvasComponent canvasState, Offset position) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    title: const Text('حذف',
                        style: TextStyle(color: Colors.white)),
                    dense: true,
                    onTap: () {
                      rs.manager?.send(
                          DeleteNodeEvent(canvasState.contextMenuNodeId!));
                      rs.manager?.send(HideContextMenuEvent());
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
