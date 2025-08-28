// FILE: lib/modules/visual_formula_editor/ui/screens/visual_formula_editor_screen.dart
// (English comments for code clarity)
// MODIFIED v3.0: MAJOR BUG FIX - Refactored settings panel logic to prevent double-opening.
// The logic is moved from the build method to a dedicated listener (_handleEditorStateChange)
// to ensure the side-effect (showing the bottom sheet) happens only once per state change.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/context_menu_widget.dart';
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
  // Local state to track if a settings sheet is currently being shown or is visible.
  EntityId? _currentlyVisibleSettingsNodeId;

  @override
  void initState() {
    super.initState();
    // Subscribe to changes in the editor's state.
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .addListener(_handleEditorStateChange);
  }

  @override
  void didUpdateWidget(covariant VisualFormulaEditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the entity ID changes (unlikely but good practice), update the listener.
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
    // Clean up the listener to prevent memory leaks.
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .removeListener(_handleEditorStateChange);
    super.dispose();
  }

  /// This listener is the single source of truth for triggering the settings panel.
  void _handleEditorStateChange() {
    final canvasState = widget.renderingSystem
        .get<EditorCanvasComponent>(widget.editorEntityId);
    if (canvasState == null) return;

    // Condition to SHOW the panel:
    // The logic world wants a panel to be open (`settingsNodeId` is not null)
    // AND we are not currently tracking a visible panel.
    if (canvasState.settingsNodeId != null &&
        canvasState.settingsNodeId != _currentlyVisibleSettingsNodeId) {
      // Update our local tracker immediately.
      _currentlyVisibleSettingsNodeId = canvasState.settingsNodeId;

      // Schedule the bottom sheet to be shown after the current build frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showSettingsBottomSheet(
              context, widget.renderingSystem, canvasState.settingsNodeId!);
        }
      });
    }
    // Condition to RESET our local tracker:
    // The logic world says no panel should be open (`settingsNodeId` is null)
    // AND we are still tracking a visible panel locally.
    else if (canvasState.settingsNodeId == null &&
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
      isScrollControlled: true, // Important for text fields
      builder: (ctx) => NodeSettingsPanel(
        renderingSystem: rs,
        nodeId: nodeId,
        node: node,
      ),
    ).whenComplete(() {
      // When the sheet is dismissed by any means (dragging, back button, etc.),
      // send an event to the logic world to update the official state.
      // This ensures a clean, one-way data flow.
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

          // The logic for showing the panel has been moved to the listener.
          // The build method is now clean and only responsible for rendering.

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
            ],
          );
        },
      ),
    );
  }
}
