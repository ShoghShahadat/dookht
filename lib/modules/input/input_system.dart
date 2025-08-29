// FILE: lib/modules/input/input_system.dart
// (English comments for code clarity)
// MODIFIED v8.0: FINAL VERSION - Reverted to the most robust and simple
// event-driven model. This ensures immediate and reliable processing of
// user input without unnecessary complexity.

import 'dart:async';
import 'package:nexus/nexus.dart';

/// A central system that listens for input events (like taps) sent from the UI
/// and triggers the corresponding logic in the background isolate.
class InputSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen for tap events and process them immediately. This is the most
    // direct and reliable approach for this application's needs.
    listen<EntityTapEvent>(_onTap);
  }

  void _onTap(EntityTapEvent event) {
    final entity = world.entities[event.id];
    if (entity == null) return;

    final clickable = entity.get<ClickableComponent>();
    clickable?.onTap(entity);
  }

  // This system is purely event-driven and does not need an update loop.
  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
