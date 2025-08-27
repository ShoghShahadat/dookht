// FILE: lib/modules/customers/customer_system.dart
// (English comments for code clarity)

import 'package:collection/collection.dart';
// Corrected the broken import paths
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
    listen<DataLoadedEvent>(_onDataLoaded);
  }

  void _onDataLoaded(DataLoadedEvent event) {
    // Find all entities that have been loaded and are tagged as 'customer'.
    final customerEntities = world.entities.values
        .where((e) => e.get<TagsComponent>()?.hasTag('customer') ?? false)
        .toList();

    // --- FIX: The redundant logic to add LifecyclePolicyComponent is removed from here. ---
    // The PersistenceSystem is now the single source of truth for this logic,
    // ensuring all loaded entities are correctly marked as persistent.
    final customerIds = customerEntities.map((e) => e.id).toList();

    // Update the UI container with the list of loaded customers.
    final listContainer = _getListContainer();
    if (listContainer != null) {
      listContainer.add(ChildrenComponent(customerIds));
    }
  }

  void _onAddCustomer(AddCustomerEvent event) {
    final newCustomer = Entity()
      ..add(TagsComponent({'customer'}))
      // Correctly set on creation
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
      final childrenComp = listContainer.get<ChildrenComponent>()!;
      final newChildren = List<EntityId>.from(childrenComp.children)
        ..add(newCustomer.id);
      listContainer.add(ChildrenComponent(newChildren));
    }

    // Fire the correct event to trigger immediate saving.
    world.eventBus.fire(SaveDataEvent());
  }

  Entity? _getListContainer() {
    return world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
