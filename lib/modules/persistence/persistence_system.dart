import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'persistence_events.dart' hide SaveDataEvent;

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
    try {
      _storage = services.get<StorageAdapter>();
      await _load();
    } catch (e) {
      debugPrint(
          '[PersistenceSystem] Could not get StorageAdapter or load data: $e');
    }
  }

  Future<void> _handleSave(SaveDataEvent event) async {
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
    }
  }

  Future<void> _load() async {
    if (_storage == null || _hasLoaded) return;
    _hasLoaded = true;

    final allData = await _storage!.loadAll();
    if (allData.isEmpty) {
      debugPrint('[PersistenceSystem] No data to load.');
      world.eventBus.fire(DataLoadedEvent()); // Fire event even if no data
      return;
    }

    // Re-create entities from saved data.
    for (final key in allData.keys) {
      final entityData = allData[key]!;
      // Find if an entity with this persistence key already exists (e.g. from a module)
      var entity = world.entities.values.firstWhereOrNull(
          (e) => e.get<PersistenceComponent>()?.storageKey == key);

      entity ??= Entity();

      for (final typeName in entityData.keys) {
        final componentJson = entityData[typeName]!;
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeName, componentJson);
          entity.add(component);
        } catch (e) {
          debugPrint(
              '[PersistenceSystem] Error deserializing component $typeName for key $key: $e');
        }
      }

      if (!world.entities.containsKey(entity.id)) {
        world.addEntity(entity);
      }
    }

    debugPrint(
        '[PersistenceSystem] Loaded ${allData.length} entities from storage.');
    // Notify the rest of the app that the initial data load is complete.
    world.eventBus.fire(DataLoadedEvent());
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
