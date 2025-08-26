import 'package:nexus/nexus.dart';

/// A Nexus module that sets up the UI entity for the "Method Management" page.
class MethodManagementModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    final methodManagementPage = Entity()
      ..add(TagsComponent({'method_management_page'}))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(methodManagementPage);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [];
}
