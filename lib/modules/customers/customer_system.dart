// FILE: lib/modules/customers/customer_system.dart
// (English comments for code clarity)
// FINAL FIX v3: The system is now responsible for creating the
// 'customer_list_container' entity if it doesn't exist. This makes the
// system self-sufficient and resolves the startup race condition permanently.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_result_component.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:tailor_assistant/modules/customers/components/measurement_component.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/lifecycle/app_lifecycle_system.dart';

class CustomerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AddCustomerEvent>(_onAddCustomer);
    listen<DataRestoredEvent>(_onDataRestored);
  }

  void _onDataRestored(DataRestoredEvent event) {
    debugPrint(
        "🙋 [CustomerSystem] 4. Received DataRestoredEvent with ${event.restoredCustomerIds.length} customer IDs.");
    final listContainer = _findOrCreateListContainer();
    listContainer.add(ChildrenComponent(event.restoredCustomerIds));
    debugPrint(
        "🙋 [CustomerSystem] 5. ✅ Successfully updated the UI list container.");
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

    final listContainer = _findOrCreateListContainer();
    final childrenComp =
        listContainer.get<ChildrenComponent>() ?? ChildrenComponent([]);
    final newChildren = List<EntityId>.from(childrenComp.children)
      ..add(newCustomer.id);
    listContainer.add(ChildrenComponent(newChildren));

    world.eventBus.fire(SaveDataEvent());
  }

  Entity _findOrCreateListContainer() {
    var container = world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);

    if (container == null) {
      debugPrint(
          "⚠️ [CustomerSystem] 'customer_list_container' not found. Creating it now.");
      container = Entity()
        ..add(TagsComponent({'customer_list_container'}))
        ..add(LifecyclePolicyComponent(isPersistent: true))
        ..add(ChildrenComponent([]));
      world.addEntity(container);
    }
    return container;
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
