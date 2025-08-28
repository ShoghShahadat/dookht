// FILE: lib/modules/visual_formula_editor/systems/editor_interaction_system.dart
// (English comments for code clarity)
// REFACTORED v1.2: This system now solely focuses on selection logic.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// Handles discrete user interactions like tapping on elements to select them.
class EditorInteractionSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CanvasTapUpEvent>(_onTapUp);
  }

  void _onTapUp(CanvasTapUpEvent event) {
    final canvasEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    final canvasX = (event.localX - canvasState.panX) / canvasState.zoom;
    final canvasY = (event.localY - canvasState.panY) / canvasState.zoom;

    // First, check for a tap on a node.
    final nodeHit = getNodeAt(world, canvasX, canvasY);
    if (nodeHit != null) {
      world.eventBus.fire(SelectEntityEvent(nodeHit.id));
      return;
    }

    // If no node was hit, check for a connection.
    final connectionHit = getConnectionAt(world, canvasX, canvasY);
    if (connectionHit != null) {
      world.eventBus.fire(SelectEntityEvent(connectionHit.id));
      return;
    }

    // If nothing was hit, deselect everything.
    world.eventBus.fire(SelectEntityEvent(null));
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven
  @override
  void update(Entity entity, double dt) {}
}
