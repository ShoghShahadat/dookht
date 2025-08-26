import 'package:nexus/nexus.dart';
import 'customer_events.dart';
import 'customer_system.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A Nexus module that sets up the entities and systems for the customer feature.
class CustomerListModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // --- Add Customer Button Entity ---
    final addCustomerButton = Entity()
      ..add(TagsComponent({'add_customer_button'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(ClickableComponent((entity) {
        world.eventBus.fire(ShowAddCustomerFormEvent());
      }));
    world.addEntity(addCustomerButton);

    // --- Method Management Button Entity ---
    final methodManagementButton = Entity()
      ..add(TagsComponent({'method_management_button'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(ClickableComponent((entity) {
        world.eventBus.fire(ShowMethodManagementEvent());
      }));
    world.addEntity(methodManagementButton);

    // --- Customer List Container Entity ---
    final customerListContainer = Entity()
      ..add(TagsComponent({'customer_list_container'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(ChildrenComponent([]));
    world.addEntity(customerListContainer);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        // Provide the system that handles customer logic.
        _SingleSystemProvider([CustomerSystem()])
      ];
}
