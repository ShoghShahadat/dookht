import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';
import 'package:tailor_assistant/modules/persistence/persistence_events.dart'
    hide SaveDataEvent;

/// A system that handles saving and loading entities with a [PersistenceComponent].
class PersistenceSystem extends System {
  StorageAdapter? _storage;
  bool _hasLoaded = false;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen for the framework's built-in SaveDataEvent.
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

    if (entitiesToSave.isEmpty) return;

    debugPrint(
        '[PersistenceSystem] Received SaveDataEvent. Saving ${entitiesToSave.length} entities...');

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
      debugPrint('[PersistenceSystem] -> Saved data for key: $key');
    }
  }

  Future<void> _load() async {
    if (_storage == null || _hasLoaded) return;
    _hasLoaded = true;

    final allData = await _storage!.loadAll();
    if (allData.isEmpty) {
      debugPrint('[PersistenceSystem] No data to load.');
      world.eventBus.fire(DataLoadedEvent());
      return;
    }

    for (final key in allData.keys) {
      final entityData = allData[key]!;
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
    world.eventBus.fire(DataLoadedEvent());
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
