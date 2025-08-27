// FILE: lib/modules/lifecycle/app_lifecycle_system.dart
// (English comments for code clarity)
// FINAL, ROBUST FIX v19: The root cause is corrupted data in Hive where
// CustomerComponent is missing. This fix makes the restoration logic more
// resilient by identifying customers based on the 'customer_' prefix in their
// persistent storageKey, rather than relying on the presence of a component.
// This breaks the corruption cycle and correctly restores the UI.

import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:nexus/nexus.dart' hide AppLifecycleEvent;
import 'package:nexus/src/events/app_lifecycle_event.dart';
import 'package:tailor_assistant/core/type_id_provider.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:tailor_assistant/services/hive_storage_adapter.dart';

class DataRestoredEvent {
  final List<EntityId> restoredCustomerIds;
  DataRestoredEvent(this.restoredCustomerIds);
}

class AppLifecycleSystem extends System {
  bool _hasRestored = false;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AppLifecycleEvent>(_onLifecycleChange);
    listen<SaveDataEvent>((_) => _saveAllData());
  }

  @override
  void update(Entity entity, double dt) {
    if (!_hasRestored) {
      _restorePersistedData();
      _hasRestored = true;
    }
  }

  Future<void> _saveAllData() async {
    debugPrint("💾 [LifecycleSystem] ➡️ Initiating save...");
    final box = Hive.box(HiveStorageAdapter.boxName);
    final entitiesToSave =
        world.entities.values.where((e) => e.has<PersistenceComponent>());

    for (final entity in entitiesToSave) {
      final key = entity.get<PersistenceComponent>()!.storageKey;
      final entityJson = <String, dynamic>{};

      debugPrint("💾 Saving Entity ID ${entity.id} with storageKey: $key");
      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          final typeId = appComponentTypeIdProvider(component);
          entityJson[typeId] = (component as SerializableComponent).toJson();
          debugPrint("   - Component Key: '$typeId'");
        }
      }
      await box.put('nexus_$key', jsonEncode(entityJson));
    }
    debugPrint("💾 [LifecycleSystem] ✅ Save complete.");
  }

  void _restorePersistedData() {
    debugPrint("🔄 [LifecycleSystem] 1. Starting data restoration...");
    final bootstrapEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('bootstrap_data') ?? false);

    if (bootstrapEntity == null) {
      debugPrint("🔄 [LifecycleSystem] 2. No bootstrap data found.");
      world.eventBus.fire(DataRestoredEvent([]));
      return;
    }

    final blackboard = bootstrapEntity.get<BlackboardComponent>();
    final persistedRawData = blackboard
            ?.get<Map<String, Map<String, dynamic>>>('persistedRawData') ??
        {};

    world.removeEntity(bootstrapEntity.id);

    if (persistedRawData.isEmpty) {
      debugPrint("🔄 [LifecycleSystem] 2. Persisted data is empty.");
      world.eventBus.fire(DataRestoredEvent([]));
      return;
    }

    debugPrint(
        "🔄 [LifecycleSystem] 2. Found ${persistedRawData.length} items to restore.");
    final List<EntityId> restoredCustomerIds = [];

    for (final entry in persistedRawData.entries) {
      final storageKey = entry.key;
      final entityData = entry.value;
      final entity = Entity();

      // --- ROBUST FIX: Identify customer by storageKey prefix ---
      final bool isCustomer = storageKey.startsWith('customer_');

      for (final typeId in entityData.keys) {
        final componentJson = entityData[typeId]!;
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeId, componentJson);
          entity.add(component);
        } catch (e) {
          debugPrint("Error creating component with typeId '$typeId': $e");
        }
      }
      entity.add(LifecyclePolicyComponent(isPersistent: true));
      entity.add(PersistenceComponent(storageKey));

      if (isCustomer) {
        final tags = entity.get<TagsComponent>() ?? TagsComponent();
        tags.add('customer');
        entity.add(tags);

        // Ensure a CustomerComponent exists, even if it's empty, to prevent crashes.
        if (!entity.has<CustomerComponent>()) {
          entity.add(CustomerComponent(
              firstName: 'بازیابی شده', lastName: '', phone: ''));
        }

        restoredCustomerIds.add(entity.id);
        debugPrint(
            "🔄 [LifecycleSystem]    - Restored CUSTOMER: ${entity.id} (Key: $storageKey)");
      } else {
        debugPrint(
            "🔄 [LifecycleSystem]    - Restored ENTITY: ${entity.id} (Key: $storageKey)");
      }

      world.addEntity(entity);
    }

    debugPrint(
        "🔄 [LifecycleSystem] 3. Restoration complete. Firing DataRestoredEvent with ${restoredCustomerIds.length} customer IDs.");
    world.eventBus.fire(DataRestoredEvent(restoredCustomerIds));
  }

  void _onLifecycleChange(AppLifecycleEvent event) {
    final isLosingFocus = event.status == AppLifecycleStatus.paused ||
        event.status == AppLifecycleStatus.detached ||
        event.status == AppLifecycleStatus.hidden;

    if (isLosingFocus) {
      _saveAllData();
    }
  }

  @override
  bool matches(Entity entity) =>
      !_hasRestored &&
      (entity.get<TagsComponent>()?.hasTag('bootstrap_data') ?? false);
}
