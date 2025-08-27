// FILE: lib/modules/persistence/persistence_system.dart
// (English comments for code clarity)
// This version is now fully compatible with the new framework lifecycle.

import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';

/// A system that handles saving and loading entities with a [PersistenceComponent].
class PersistenceSystem extends System {
  StorageAdapter? _storage;
  bool _hasLoaded = false;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<SaveDataEvent>(_handleSave);
  }

  @override
  Future<void> init() async {
    // This is now guaranteed to run AFTER all initial entities are created.
    try {
      debugPrint(
          "  [Init] ➡️ [PersistenceSystem] Attempting to get StorageAdapter...");
      _storage = services.get<StorageAdapter>();
      debugPrint(
          "  [Init] ✅ [PersistenceSystem] StorageAdapter retrieved successfully.");
      await _load();
    } catch (e) {
      debugPrint(
          '  [Init] ❌ [PersistenceSystem] FATAL ERROR: Could not get StorageAdapter or load data: $e');
    }
  }

  Future<void> _handleSave(SaveDataEvent event) async {
    debugPrint("💾 [Save Flow] ➡️ [PersistenceSystem] Received SaveDataEvent.");
    if (_storage == null) return;
    final entitiesToSave =
        world.entities.values.where((e) => e.has<PersistenceComponent>());

    for (final entity in entitiesToSave) {
      final key = entity.get<PersistenceComponent>()!.storageKey;
      final entityJson = <String, dynamic>{};

      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          entityJson[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      await _storage!.save('nexus_$key', entityJson);
      debugPrint(
          "💾 [Save Flow] ✅ [PersistenceSystem] Saved Entity with key '$key'.");
    }
  }

  Future<void> _load() async {
    if (_storage == null || _hasLoaded) return;
    _hasLoaded = true;

    final allData = await _storage!.loadAll();
    if (allData.isEmpty) {
      debugPrint(
          '📂 [Load Flow] ➡️ [PersistenceSystem] No data found in storage.');
      // **CRITICAL**: Even if no data is loaded, we must fire the event
      // to signal that the loading process is complete.
      world.eventBus.fire(DataLoadedEvent());
      debugPrint(
          '🏁 [Load Flow] ✅ [PersistenceSystem] Fired DataLoadedEvent (no data).');
      return;
    }

    debugPrint(
        '📂 [Load Flow] ➡️ [PersistenceSystem] Found ${allData.length} keys to load: ${allData.keys}');

    for (final key in allData.keys) {
      final entityData = allData[key]!;
      final entity = Entity();

      for (final typeName in entityData.keys) {
        final componentJson = entityData[typeName]!;
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeName, componentJson);
          entity.add(component);
        } catch (e) {
          debugPrint(
              '📂 [Load Flow] ❌ [PersistenceSystem] Error deserializing component $typeName for key $key: $e');
        }
      }

      // **FINAL FIX**: Ensure every loaded entity is marked as persistent
      // AND gets the correct 'customer' tag if it is a customer.
      entity.add(LifecyclePolicyComponent(isPersistent: true));
      if (entity.has<CustomerComponent>()) {
        final tags = entity.get<TagsComponent>() ?? TagsComponent();
        tags.add('customer');
        entity.add(tags);
      }

      world.addEntity(entity);
      debugPrint(
          "📂 [Load Flow] ✅ [PersistenceSystem] Reconstructed and added Entity ID ${entity.id} for key '$key'.");
    }

    world.eventBus.fire(DataLoadedEvent());
    debugPrint('🏁 [Load Flow] ✅ [PersistenceSystem] Fired DataLoadedEvent.');
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
