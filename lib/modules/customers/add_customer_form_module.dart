import 'package:nexus/nexus.dart';

/// A Nexus module that sets up the UI entity for the "Add Customer" form.
class AddCustomerFormModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    final addCustomerForm = Entity()
      ..add(TagsComponent({'add_customer_form'}))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    // This entity doesn't need a Clickable component itself.
    // The logic will be handled by the form's widget builder.
    world.addEntity(addCustomerForm);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [];
}
