import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/input_events.dart';

/// A system that listens for input events sent from the UI thread and
/// triggers the corresponding logic in the background isolate.
class InputSystem extends System {
  StreamSubscription? _tapSubscription;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // DEBUG LOG ADDED
    debugPrint("👂 [InputSystem] Now listening for EntityTapEvent.");
    _tapSubscription = world.eventBus.on<EntityTapEvent>(_onTap);
  }

  @override
  void onRemovedFromWorld() {
    _tapSubscription?.cancel();
    super.onRemovedFromWorld();
  }

  void _onTap(EntityTapEvent event) {
    // DEBUG LOGS ADDED
    debugPrint("✅ [InputSystem] Received EntityTapEvent for ID: ${event.id}");
    final entity = world.entities[event.id];
    if (entity == null) {
      debugPrint("  - ❌ Entity with ID ${event.id} not found.");
      return;
    }

    final clickable = entity.get<ClickableComponent>();
    if (clickable == null) {
      debugPrint("  - ❌ ClickableComponent not found on Entity ${event.id}.");
      return;
    }

    debugPrint("  - ▶️ Executing onTap callback for Entity ${event.id}.");
    clickable.onTap(entity);
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
