// FILE: lib/modules/visual_formula_editor/systems/editor_interaction_system.dart
// (English comments for code clarity)
// This system handles discrete interactions like taps.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// Handles discrete user interactions like tapping on elements.
class EditorInteractionSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CanvasTapUpEvent>(_onTapUp);
  }

  void _onTapUp(CanvasTapUpEvent event) {
    // The primary tap action is to delete a connection by tapping near its midpoint.
    final connectionToDelete =
        getConnectionAt(world, event.localX, event.localY);
    if (connectionToDelete != null) {
      world.eventBus.fire(DeleteConnectionEvent(connectionToDelete.id));
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven
  @override
  void update(Entity entity, double dt) {}
}
