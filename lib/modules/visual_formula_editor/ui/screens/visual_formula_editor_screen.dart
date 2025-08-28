// FILE: lib/modules/visual_formula_editor/ui/screens/visual_formula_editor_screen.dart
// (English comments for code clarity)
// MODIFIED v4.0: Added the new FormulaTextEditorWidget to the layout.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/context_menu_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/formula_text_editor_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/interactive_canvas_layer.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/node_settings_panel.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/preview_panel_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/toolbar_widget.dart';

class VisualFormulaEditorScreen extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId methodId;
  final EntityId editorEntityId;

  const VisualFormulaEditorScreen({
    super.key,
    required this.renderingSystem,
    required this.methodId,
    required this.editorEntityId,
  });

  @override
  State<VisualFormulaEditorScreen> createState() =>
      _VisualFormulaEditorScreenState();
}

class _VisualFormulaEditorScreenState extends State<VisualFormulaEditorScreen> {
  EntityId? _currentlyVisibleSettingsNodeId;

  @override
  void initState() {
    super.initState();
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .addListener(_handleEditorStateChange);
  }

  @override
  void didUpdateWidget(covariant VisualFormulaEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editorEntityId != oldWidget.editorEntityId) {
      widget.renderingSystem
          .getNotifier(oldWidget.editorEntityId)
          .removeListener(_handleEditorStateChange);
      widget.renderingSystem
          .getNotifier(widget.editorEntityId)
          .addListener(_handleEditorStateChange);
    }
  }

  @override
  void dispose() {
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .removeListener(_handleEditorStateChange);
    super.dispose();
  }

  void _handleEditorStateChange() {
    final canvasState = widget.renderingSystem
        .get<EditorCanvasComponent>(widget.editorEntityId);
    if (canvasState == null) return;

    if (canvasState.settingsNodeId != null &&
        canvasState.settingsNodeId != _currentlyVisibleSettingsNodeId) {
      _currentlyVisibleSettingsNodeId = canvasState.settingsNodeId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSettingsBottomSheet(
              context, widget.renderingSystem, canvasState.settingsNodeId!);
        }
      });
    } else if (canvasState.settingsNodeId == null &&
        _currentlyVisibleSettingsNodeId != null) {
      _currentlyVisibleSettingsNodeId = null;
    }
  }

  void _showSettingsBottomSheet(
      BuildContext context, FlutterRenderingSystem rs, EntityId nodeId) {
    final node = rs.get<NodeComponent>(nodeId);
    if (node == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (ctx) => NodeSettingsPanel(
        renderingSystem: rs,
        nodeId: nodeId,
        node: node,
      ),
    ).whenComplete(() {
      rs.manager?.send(CloseNodeSettingsEvent());
    });
  }

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
      backgroundColor: Colors.black,
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

          if (canvasState == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              InteractiveCanvasLayer(
                renderingSystem: rs,
                nodeIds: nodeIds,
                connectionIds: connectionIds,
                canvasState: canvasState,
              ),
              ContextMenuWidget(
                renderingSystem: rs,
                canvasState: canvasState,
              ),
              ToolbarWidget(renderingSystem: rs),
              PreviewPanelWidget(
                renderingSystem: rs,
                nodeIds: nodeIds,
                canvasState: canvasState,
                textColor: textColor,
              ),
              // ADDED: The new formula text editor widget
              FormulaTextEditorWidget(
                renderingSystem: rs,
                editorEntityId: widget.editorEntityId,
              ),
            ],
          );
        },
      ),
    );
  }
}
