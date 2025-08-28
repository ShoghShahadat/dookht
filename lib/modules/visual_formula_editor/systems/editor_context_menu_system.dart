// FILE: lib/modules/visual_formula_editor/systems/editor_context_menu_system.dart
// (English comments for code clarity)
// FIX v1.1: Added the missing import for editor_events.dart, which resolves the compile error.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart'; // FIX: Missing import added
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// Manages the state of the right-click context menu in the editor.
class EditorContextMenuSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CanvasLongPressStartEvent>(_onLongPressStart);
    listen<HideContextMenuEvent>(_onHideContextMenu);
  }

  Entity? _getCanvasEntity() {
    return world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
  }

  void _onLongPressStart(CanvasLongPressStartEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    // Convert local press position to canvas coordinates
    final canvasX = (event.localX - canvasState.panX) / canvasState.zoom;
    final canvasY = (event.localY - canvasState.panY) / canvasState.zoom;

    final nodeHit = getNodeAt(world, canvasX, canvasY);
    if (nodeHit != null) {
      // Use the node's actual position for the menu, not the press position
      final nodePos = nodeHit.get<NodeComponent>()!.position;
      canvasEntity.add(canvasState.copyWith(
        contextMenuNodeId: nodeHit.id,
        contextMenuX: nodePos.x,
        contextMenuY: nodePos.y,
      ));
    }
  }

  void _onHideContextMenu(HideContextMenuEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(canvasState.copyWith(
      clearContextMenuNodeId: true,
      clearContextMenuX: true,
      clearContextMenuY: true,
    ));
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven
  @override
  void update(Entity entity, double dt) {}
}
