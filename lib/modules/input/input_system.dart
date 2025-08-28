// FILE: lib/modules/input/input_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: Added specialized logging.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';

/// A central system that listens for input events (like taps) sent from the UI
/// and triggers the corresponding logic in the background isolate.
class InputSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen for tap events coming from the rendering layer.
    listen<EntityTapEvent>(_onTap);
  }

  void _onTap(EntityTapEvent event) {
    debugPrint(
        "[LOG | InputSystem] --> Received EntityTapEvent for ID: ${event.id}.");
    // Find the entity that was tapped using its ID.
    final entity = world.entities[event.id];
    if (entity == null) {
      debugPrint(
          "[LOG | InputSystem] --! Aborted: Entity with ID ${event.id} not found.");
      return;
    }

    // Get the ClickableComponent attached to that entity.
    final clickable = entity.get<ClickableComponent>();

    if (clickable != null) {
      debugPrint(
          "[LOG | InputSystem] <-- Executing ClickableComponent's onTap for entity ${event.id}.");
      // Execute the onTap function associated with that component.
      clickable.onTap(entity);
    } else {
      debugPrint(
          "[LOG | InputSystem] --! Warning: Entity ${event.id} received a tap event but has no ClickableComponent.");
    }
  }

  @override
  bool matches(Entity entity) => false; // This system is purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
