// FILE: lib/modules/lifecycle/app_lifecycle_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: CRITICAL REFACTOR - This system is now the single source of
// truth for both SAVING and LOADING all persistent data.
// - Added a robust data loading mechanism in the `init()` method.
// - It now correctly reconstructs all entities from Hive.
// - It populates the customer list container after loading.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/app_lifecycle_event.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:tailor_assistant/services/hive_storage_adapter.dart';
import 'package:collection/collection.dart';

/// A system that listens for application lifecycle changes and triggers
/// actions, such as saving and loading data.
class AppLifecycleSystem extends System {
  bool _hasLoaded = false;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AppLifecycleEvent>(_onLifecycleChange);
    listen<SaveDataEvent>((_) => _saveAllData());
  }

  /// The init method is the perfect place for one-time setup logic like loading data.
  /// It runs after all modules are loaded but before the first update tick.
  @override
  Future<void> init() async {
    if (_hasLoaded) return;
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

  /// Loads all persisted entities from Hive and reconstructs the world state.
  Future<void> _loadAllData() async {
    debugPrint("📂 [Persistence] ➡️ Initiating load...");
    final box = Hive.box(HiveStorageAdapter.boxName);

    if (box.isEmpty) {
      debugPrint("📂 [Persistence] 🧐 No data found in storage to load.");
      return;
    }

    final List<EntityId> reconstructedCustomerIds = [];

    for (final key in box.keys) {
      if (key is! String || !key.startsWith('nexus_')) continue;

      final jsonString = box.get(key) as String?;
      if (jsonString == null) continue;

      final entityData = jsonDecode(jsonString) as Map<String, dynamic>;
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

      // Ensure all loaded entities are marked as persistent
      if (!entity.has<LifecyclePolicyComponent>()) {
        entity.add(LifecyclePolicyComponent(isPersistent: true));
      }

      world.addEntity(entity);

      // If it's a customer, keep track of its ID to populate the list later
      if (entity.has<CustomerComponent>()) {
        reconstructedCustomerIds.add(entity.id);
      }
      debugPrint(
          "📂 [Persistence] ✅ Reconstructed Entity ID ${entity.id} for key '$key'.");
    }

    // After all entities are loaded, update the UI container for the customer list.
    final listContainer = world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);

    if (listContainer != null) {
      listContainer.add(ChildrenComponent(reconstructedCustomerIds));
      debugPrint(
          "📂 [Persistence] ✅ Updated customer_list_container with ${reconstructedCustomerIds.length} customers.");
    }
  }

  /// Saves all entities with a PersistenceComponent to Hive.
  Future<void> _saveAllData() async {
    debugPrint("💾 [Persistence] ➡️ Initiating save...");
    final box = Hive.box(HiveStorageAdapter.boxName);

    final entitiesToSave =
        world.entities.values.where((e) => e.has<PersistenceComponent>());

    if (entitiesToSave.isEmpty) {
      debugPrint("💾 [Persistence] 🧐 No persistent entities found to save.");
      return;
    }

    // Use a map to batch writes for better performance
    final Map<String, String> writes = {};

    for (final entity in entitiesToSave) {
      final key = entity.get<PersistenceComponent>()!.storageKey;
      final entityJson = <String, dynamic>{};

      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          entityJson[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      writes['nexus_$key'] = jsonEncode(entityJson);
    }

    await box.putAll(writes);
    debugPrint("💾 [Persistence] ✅ Saved ${writes.length} entities.");
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
