// FILE: lib/modules/visual_formula_editor/ui/visual_formula_editor_builder.dart
// (English comments for code clarity)
// REFACTORED v5.0: This file is now a clean entry point, delegating all UI work.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/visual_formula_editor_widget.dart';

/// The main IWidgetBuilder for the visual formula editor feature.
/// Its sole responsibility is to find the correct entity IDs and build the main widget.
class VisualFormulaEditorBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    final viewManagerId = rs.getAllIdsWithTag('view_manager').firstOrNull;
    if (viewManagerId == null) return const SizedBox.shrink();

    final viewState = rs.get<ViewStateComponent>(viewManagerId);
    final activeMethodId = viewState?.activeMethodId;
    if (activeMethodId == null) {
      return const Center(
          child: Text('No method selected for visual editing.'));
    }

    // Delegate the entire UI construction to the specialized widget.
    return VisualFormulaEditorWidget(
      renderingSystem: rs,
      methodId: activeMethodId,
      editorEntityId: entityId,
    );
  }
}
