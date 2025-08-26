import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'components/customer_component.dart';
import 'customer_events.dart';

/// The core logic system for managing customer data.
class CustomerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Listen for the event that is fired when the user submits the 'add customer' form.
    listen<AddCustomerEvent>(_onAddCustomer);
  }

  void _onAddCustomer(AddCustomerEvent event) {
    // 1. Create a new entity for the customer.
    final newCustomer = Entity()
      ..add(TagsComponent({'customer'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(CustomerComponent(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      ))
      // Add a PersistenceComponent to mark this entity for saving.
      // The storage key is unique to this customer.
      ..add(PersistenceComponent(
          'customer_${DateTime.now().millisecondsSinceEpoch}'));

    world.addEntity(newCustomer);

    // 2. Find the central list container entity.
    final listContainer = world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);

    if (listContainer != null) {
      // 3. Update the list container's children to include the new customer.
      final childrenComp = listContainer.get<ChildrenComponent>()!;
      final newChildren = List<EntityId>.from(childrenComp.children)
        ..add(newCustomer.id);
      listContainer.add(ChildrenComponent(newChildren));
    }

    // 4. Fire an event to notify other systems (like the PersistenceSystem)
    // that they should save all persistent data now.
    world.eventBus.fire(SaveDataEvent());
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
