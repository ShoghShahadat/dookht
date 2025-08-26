import 'package:collection/collection.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_result_component.dart';
import 'package:tailor_assistant/modules/customers/components/customer_component.dart';
import 'package:tailor_assistant/modules/customers/components/measurement_component.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/persistence/persistence_system.dart';

/// The core logic system for managing customer data.
class CustomerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AddCustomerEvent>(_onAddCustomer);
    listen<DataLoadedEvent>(_onDataLoaded);
  }

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

  void _onAddCustomer(AddCustomerEvent event) {
    final newCustomer = Entity()
      ..add(TagsComponent({'customer'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(CustomerComponent(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
      ))
      // Add empty components to initialize the customer's state.
      ..add(MeasurementComponent())
      ..add(CalculationResultComponent())
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
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
