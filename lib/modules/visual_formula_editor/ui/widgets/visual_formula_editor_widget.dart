// FILE: lib/modules/visual_formula_editor/ui/widgets/visual_formula_editor_widget.dart
// (English comments for code clarity)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/painters/formula_canvas_painter.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/preview_panel_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/toolbar_widget.dart';

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
  Offset? _panStart;

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
        animation: rs.getNotifier(widget.editorEntityId),
        builder: (context, _) {
          final nodeIds = rs.getAllIdsWithTag('node_component');
          final connectionIds = rs.getAllIdsWithTag('connection_component');
          final canvasState =
              rs.get<EditorCanvasComponent>(widget.editorEntityId);

          // Convert canvas coordinates to screen coordinates for the menu
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
              GestureDetector(
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
                      CanvasPointerUpEvent(localX: canvasX, localY: canvasY));
                },
                onLongPressStart: (details) {
                  final canvasState =
                      rs.get<EditorCanvasComponent>(widget.editorEntityId);
                  if (canvasState == null) return;
                  final canvasX =
                      (details.localPosition.dx - canvasState.panX) /
                          canvasState.zoom;
                  final canvasY =
                      (details.localPosition.dy - canvasState.panY) /
                          canvasState.zoom;
                  rs.manager?.send(ShowNodeContextMenuEvent(
                      nodeId: -1,
                      x: canvasX,
                      y: canvasY)); // ID is found in system
                },
                onScaleStart: (details) {
                  _panStart = details.localFocalPoint;
                },
                onScaleUpdate: (details) {
                  if (details.scale != 1.0) {
                    rs.manager?.send(CanvasZoomEvent(
                      zoomDelta: details.scale,
                      localX: details.localFocalPoint.dx,
                      localY: details.localFocalPoint.dy,
                    ));
                  } else if (_panStart != null) {
                    final delta = details.localFocalPoint - _panStart!;
                    rs.manager?.send(
                        CanvasPanEvent(deltaX: delta.dx, deltaY: delta.dy));
                    _panStart = details.localFocalPoint;
                  }
                },
                onScaleEnd: (details) {
                  _panStart = null;
                },
                child: CustomPaint(
                  painter: FormulaCanvasPainter(
                    renderingSystem: rs,
                    nodeIds: nodeIds,
                    connectionIds: connectionIds,
                    canvasState: canvasState,
                  ),
                  child: Container(),
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
                  // Add other options like Edit, Duplicate here
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
