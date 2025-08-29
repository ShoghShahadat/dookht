// FILE: lib/modules/lifecycle/app_lifecycle_system.dart
// (English comments for code clarity)
// MODIFIED v3.0: CRITICAL REFACTOR - This system is now fully decoupled from
// Hive. It now depends on the StorageAdapter interface, which is retrieved
// from GetIt. This improves testability and adheres to SOLID principles.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/app_lifecycle_event.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:collection/collection.dart';

/// A system that listens for application lifecycle changes and triggers
/// actions, such as saving and loading data.
class AppLifecycleSystem extends System {
  bool _hasLoaded = false;
  late final StorageAdapter _storage;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AppLifecycleEvent>(_onLifecycleChange);
    listen<SaveDataEvent>((_) => _saveAllData());
  }

  @override
  Future<void> init() async {
    if (_hasLoaded) return;
    // Get the storage implementation from the service locator.
    _storage = services.get<StorageAdapter>();
    await _loadAllData();
    _hasLoaded = true;
  }

  void _onLifecycleChange(AppLifecycleEvent event) {
    final isLosingFocus = event.status == AppLifecycleStatus.paused ||
        event.status == AppLifecycleStatus.detached ||
        event.status == AppLifecycleStatus.hidden;

    if (isLosingFocus) {
      _saveAllData();
    }
  }

  /// Loads all persisted entities from the storage adapter.
  Future<void> _loadAllData() async {
    debugPrint("📂 [Persistence] ➡️ Initiating load via StorageAdapter...");
    final allData = await _storage.loadAll();

    if (allData.isEmpty) {
      debugPrint("📂 [Persistence] 🧐 No data found in storage to load.");
      return;
    }

    final List<EntityId> reconstructedCustomerIds = [];

    for (final key in allData.keys) {
      final entityData = allData[key]!;
      final entity = Entity();

      for (final typeName in entityData.keys) {
        final componentJson = entityData[typeName] as Map<String, dynamic>;
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeName, componentJson);
          entity.add(component);
        } catch (e) {
          debugPrint(
              "📂 [Persistence] ❌ Error deserializing component $typeName for key $key: $e");
        }
      }

      if (!entity.has<LifecyclePolicyComponent>()) {
        entity.add(LifecyclePolicyComponent(isPersistent: true));
      }

      world.addEntity(entity);

      if (entity.has<CustomerComponent>()) {
        reconstructedCustomerIds.add(entity.id);
      }
      debugPrint(
          "📂 [Persistence] ✅ Reconstructed Entity ID ${entity.id} for key '$key'.");
    }

    final listContainer = world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);

    if (listContainer != null) {
      listContainer.add(ChildrenComponent(reconstructedCustomerIds));
      debugPrint(
          "📂 [Persistence] ✅ Updated customer_list_container with ${reconstructedCustomerIds.length} customers.");
    }
  }

  /// Saves all entities with a PersistenceComponent via the storage adapter.
  Future<void> _saveAllData() async {
    debugPrint("💾 [Persistence] ➡️ Initiating save via StorageAdapter...");
    final entitiesToSave =
        world.entities.values.where((e) => e.has<PersistenceComponent>());

    if (entitiesToSave.isEmpty) {
      debugPrint("💾 [Persistence] 🧐 No persistent entities found to save.");
      return;
    }

    int savedCount = 0;
    for (final entity in entitiesToSave) {
      final key = entity.get<PersistenceComponent>()!.storageKey;
      final entityJson = <String, dynamic>{};

      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          entityJson[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      // The storage adapter contract expects the 'nexus_' prefix.
      await _storage.save('nexus_$key', entityJson);
      savedCount++;
    }
    debugPrint("💾 [Persistence] ✅ Saved $savedCount entities.");
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
