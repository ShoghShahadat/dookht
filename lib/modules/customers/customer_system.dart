// FILE: lib/modules/customers/customer_system.dart
// (English comments for code clarity)
// FINAL FIX: This system now handles the reconstruction of persisted entities
// inside the logic isolate, solving the component-dropping issue.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_result_component.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:tailor_assistant/modules/customers/components/measurement_component.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:nexus/nexus.dart';

/// The core logic system for managing customer data.
class CustomerSystem extends System {
  bool _hasRestored = false;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AddCustomerEvent>(_onAddCustomer);

    // The DataLoadedEvent is no longer used, as we now handle restoration directly.
    // listen<DataLoadedEvent>(_onDataLoaded);
  }

  @override
  void update(Entity entity, double dt) {
    // This method is called on every frame. We use a flag to ensure
    // the restoration logic runs only once at the beginning.
    if (!_hasRestored) {
      _restorePersistedData();
      _hasRestored = true;
    }
  }

  void _restorePersistedData() {
    debugPrint("🔄 [CustomerSystem] Starting data restoration...");
    final bootstrapEntity = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('bootstrap_data') ?? false);

    if (bootstrapEntity == null) {
      debugPrint("🔄 [CustomerSystem] No bootstrap data found.");
      return;
    }

    final blackboard = bootstrapEntity.get<BlackboardComponent>();
    final persistedRawData = blackboard
            ?.get<Map<String, Map<String, dynamic>>>('persistedRawData') ??
        {};

    if (persistedRawData.isEmpty) {
      debugPrint("🔄 [CustomerSystem] Persisted data is empty.");
      world.removeEntity(bootstrapEntity.id); // Clean up bootstrap entity
      return;
    }

    final List<EntityId> reconstructedCustomerIds = [];

    for (final entry in persistedRawData.entries) {
      final storageKey = entry.key;
      final entityData = entry.value;

      // We only reconstruct entities that have customer data to avoid conflicts
      // with entities created by other modules (like methods).
      if (!entityData.containsKey('CustomerComponent')) continue;

      final entity = Entity();
      for (final typeName in entityData.keys) {
        final componentJson = entityData[typeName]!;
        try {
          final component =
              ComponentFactoryRegistry.I.create(typeName, componentJson);
          entity.add(component);
        } catch (e) {
          debugPrint(
              "🔄 [CustomerSystem] Error creating component $typeName: $e");
        }
      }
      entity.add(LifecyclePolicyComponent(isPersistent: true));
      entity.add(PersistenceComponent(storageKey));

      final tags = entity.get<TagsComponent>() ?? TagsComponent();
      tags.add('customer');
      entity.add(tags);

      world.addEntity(entity);
      reconstructedCustomerIds.add(entity.id);
      debugPrint(
          "🔄 [CustomerSystem] ✅ Restored customer with key: $storageKey");
    }

    // Now, update the UI container with the restored customers.
    final listContainer = _getListContainer();
    if (listContainer != null) {
      listContainer.add(ChildrenComponent(reconstructedCustomerIds));
      debugPrint(
          "🔄 [CustomerSystem] ✅ Updated customer_list_container with ${reconstructedCustomerIds.length} customers.");
    }

    // Clean up the bootstrap entity as it's no longer needed.
    world.removeEntity(bootstrapEntity.id);
  }

  void _onAddCustomer(AddCustomerEvent event) {
    final newCustomer = Entity()
      ..add(TagsComponent({'customer'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(CustomerComponent(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      ))
      ..add(MeasurementComponent())
      ..add(CalculationResultComponent())
      ..add(CalculationStateComponent())
      ..add(PersistenceComponent(
          'customer_${DateTime.now().millisecondsSinceEpoch}'));

    world.addEntity(newCustomer);

    final listContainer = _getListContainer();
    if (listContainer != null) {
      final childrenComp =
          listContainer.get<ChildrenComponent>() ?? ChildrenComponent([]);
      final newChildren = List<EntityId>.from(childrenComp.children)
        ..add(newCustomer.id);
      listContainer.add(ChildrenComponent(newChildren));
    }

    world.eventBus.fire(SaveDataEvent());
  }

  Entity? _getListContainer() {
    return world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);
  }

  @override
  bool matches(Entity entity) => true; // We need update() to be called.
}
