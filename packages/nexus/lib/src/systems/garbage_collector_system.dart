// FILE: packages/nexus/lib/src/systems/garbage_collector_system.dart
// (English comments for code clarity)

import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
// --- FINAL FIX: Import the event from the persistence system to listen to it ---
import 'package:nexus/src/systems/persistence_system.dart';

/// A background system that periodically checks for and removes entities
/// that meet their destruction condition, preventing logical memory leaks.
class GarbageCollectorSystem extends System {
  double _timer = 0.0;
  final double _checkInterval; // How often to run the check, in seconds.

  // --- FINAL FIX: A flag to ensure the GC waits for the initial data load ---
  bool _initialLoadComplete = false;

  GarbageCollectorSystem({double checkInterval = 2.0})
      : _checkInterval = checkInterval;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // --- FINAL FIX: Listen for the DataLoadedEvent ---
    // This event is fired by PersistenceSystem after all data is loaded.
    listen<DataLoadedEvent>(_onDataLoaded);
    debugPrint(
        '[GarbageCollector] Initialized and is now patiently waiting for DataLoadedEvent...');
  }

  void _onDataLoaded(DataLoadedEvent event) {
    // Once data is loaded, it's safe for the GC to start working.
    debugPrint(
        '✅ [GarbageCollector] Received DataLoadedEvent! The GC is now active and will start checking for disposable entities.');
    _initialLoadComplete = true;
  }

  @override
  bool matches(Entity entity) {
    // This system doesn't operate on entities in the traditional update loop.
    return false;
  }

  @override
  void update(Entity entity, double dt) {
    // The logic is handled in runGc.
  }

  /// This method should be called once per frame from a central system.
  void runGc(double dt) {
    // --- FINAL FIX: The GC will remain dormant until the initial load is complete ---
    if (!_initialLoadComplete) {
      // Specialized Log: Waiting for data load to complete.
      // debugPrint('[GarbageCollector] Still waiting...'); // Uncomment for verbose logging
      return; // Do nothing until PersistenceSystem gives the green light.
    }

    _timer += dt;
    if (_timer < _checkInterval) {
      return;
    }
    _timer = 0.0;

    debugPrint('🧹 [GarbageCollector] Running periodic check...');
    final entitiesToCheck = List<Entity>.from(world.entities.values);
    final entitiesToRemove = <EntityId>[];

    for (final entity in entitiesToCheck) {
      final policy = entity.get<LifecyclePolicyComponent>();

      if (policy == null) {
        if (entity.id != world.rootEntity.id) {
          debugPrint(
              '    - [GC Warning] Entity ID ${entity.id} is missing a LifecyclePolicyComponent.');
        }
        continue;
      }

      if (!policy.isPersistent && policy.destructionCondition(entity)) {
        entitiesToRemove.add(entity.id);
      }
    }

    if (entitiesToRemove.isNotEmpty) {
      debugPrint(
          '    - [GC Action] Purging ${entitiesToRemove.length} entities: ${entitiesToRemove.join(', ')}');
      for (final id in entitiesToRemove) {
        world.removeEntity(id);
      }
    } else {
      debugPrint('    - [GC Result] No entities to purge in this cycle.');
    }
  }
}
