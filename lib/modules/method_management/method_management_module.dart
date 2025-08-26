import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/method_management_system.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A Nexus module that sets up the UI entity for the "Method Management" page.
class MethodManagementModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    final methodManagementPage = Entity()
      ..add(TagsComponent({'method_management_page'}))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(methodManagementPage);

    // An entity for the edit page itself.
    final editMethodPage = Entity()
      ..add(TagsComponent({'edit_method_page'}))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(editMethodPage);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        // Provide the system that handles method management logic.
        _SingleSystemProvider([MethodManagementSystem()])
      ];
}
