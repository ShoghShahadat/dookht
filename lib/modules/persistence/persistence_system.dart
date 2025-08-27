// FILE: lib/modules/persistence/persistence_system.dart
// (English comments for code clarity)

import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:collection/collection.dart';

/// A system that handles saving and loading entities with a [PersistenceComponent].
/// This system is now also responsible for directly updating the UI state after loading.
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

    if (entitiesToSave.isEmpty) return;

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
      return;
    }

    final loadedCustomerIds = <EntityId>[];

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

      // Ensure the loaded entity is marked as persistent.
      entity.add(LifecyclePolicyComponent(isPersistent: true));

      if (!world.entities.containsKey(entity.id)) {
        world.addEntity(entity);
      }

      // If this entity is a customer, add its ID to our temporary list.
      if (entity.get<TagsComponent>()?.hasTag('customer') ?? false) {
        loadedCustomerIds.add(entity.id);
      }
    }

    // --- NEW DIRECT LOGIC: Update the customer list UI directly ---
    // Find the entity that acts as the container for the customer list.
    final listContainer = world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);

    if (listContainer != null && loadedCustomerIds.isNotEmpty) {
      // Directly add the list of loaded customer IDs to its ChildrenComponent.
      listContainer.add(ChildrenComponent(loadedCustomerIds));
      debugPrint(
          '[PersistenceSystem] Directly updated customer list with ${loadedCustomerIds.length} customers.');
    }

    debugPrint(
        '[PersistenceSystem] Loaded ${allData.length} entities from storage.');
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
