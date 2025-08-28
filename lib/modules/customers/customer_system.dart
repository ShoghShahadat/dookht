// FILE: lib/modules/customers/customer_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: MAJOR REFACTOR - Removed all persistence and data restoration logic.
// This system is now a clean, simple, event-driven system responsible only for
// adding new customers. Loading is handled by AppLifecycleSystem.

import 'package:collection/collection.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_result_component.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:tailor_assistant/modules/customers/components/measurement_component.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:nexus/nexus.dart';

/// The core logic system for managing customer data.
class CustomerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AddCustomerEvent>(_onAddCustomer);
  }

  void _onAddCustomer(AddCustomerEvent event) {
    // Create a new customer entity with all its necessary components.
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
      // Assign a unique key for persistence.
      ..add(PersistenceComponent(
          'customer_${DateTime.now().millisecondsSinceEpoch}'));

    world.addEntity(newCustomer);

    // Update the UI container to include the new customer.
    final listContainer = _getListContainer();
    if (listContainer != null) {
      final childrenComp =
          listContainer.get<ChildrenComponent>() ?? ChildrenComponent([]);
      final newChildren = List<EntityId>.from(childrenComp.children)
        ..add(newCustomer.id);
      listContainer.add(ChildrenComponent(newChildren));
    }

    // Fire a global event to trigger a data save.
    world.eventBus.fire(SaveDataEvent());
  }

  Entity? _getListContainer() {
    return world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);
  }

  // This system is now purely event-driven and doesn't need an update loop.
  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
