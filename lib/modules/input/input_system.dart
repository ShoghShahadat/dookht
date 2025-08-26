import 'dart:async';
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
    // Find the entity that was tapped using its ID.
    final entity = world.entities[event.id];
    if (entity == null) return;

    // Get the ClickableComponent attached to that entity.
    final clickable = entity.get<ClickableComponent>();

    // Execute the onTap function associated with that component.
    clickable?.onTap(entity);
  }

  @override
  bool matches(Entity entity) => false; // This system is purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
