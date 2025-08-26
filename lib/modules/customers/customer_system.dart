import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../persistence/persistence_events.dart' hide SaveDataEvent;
import 'components/customer_component.dart';
import 'customer_events.dart';

/// The core logic system for managing customer data.
class CustomerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AddCustomerEvent>(_onAddCustomer);
    // Listen for the data loaded event to populate the initial list.
    listen<DataLoadedEvent>(_onDataLoaded);
  }

  /// Populates the customer list after data is loaded from storage.
  void _onDataLoaded(DataLoadedEvent event) {
    final allCustomers = world.entities.values
        .where((e) => e.get<TagsComponent>()?.hasTag('customer') ?? false)
        .map((e) => e.id)
        .toList();

    final listContainer = _getListContainer();
    if (listContainer != null) {
      listContainer.add(ChildrenComponent(allCustomers));
    }
  }

  /// Handles the creation of a new customer from the form.
  void _onAddCustomer(AddCustomerEvent event) {
    final newCustomer = Entity()
      ..add(TagsComponent({'customer'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(CustomerComponent(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      ))
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

    world.eventBus.fire(SaveDataEvent());
  }

  Entity? _getListContainer() {
    return world.entities.values.firstWhereOrNull((e) =>
        e.get<TagsComponent>()?.hasTag('customer_list_container') ?? false);
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
