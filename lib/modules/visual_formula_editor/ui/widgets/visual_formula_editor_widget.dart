// FILE: lib/modules/visual_formula_editor/ui/widgets/visual_formula_editor_widget.dart
// (English comments for code clarity)

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

          return Stack(
            children: [
              GestureDetector(
                onPanStart: (details) {
                  rs.manager?.send(CanvasPointerDownEvent(
                    localX: details.localPosition.dx,
                    localY: details.localPosition.dy,
                  ));
                },
                onPanUpdate: (details) {
                  rs.manager?.send(CanvasPointerMoveEvent(
                    deltaX: details.delta.dx,
                    deltaY: details.delta.dy,
                  ));
                },
                onPanEnd: (details) {
                  rs.manager?.send(CanvasPointerUpEvent());
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
            ],
          );
        },
      ),
    );
  }
}
