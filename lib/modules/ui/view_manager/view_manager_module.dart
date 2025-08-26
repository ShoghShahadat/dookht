import 'package:nexus/nexus.dart';
import 'view_manager_system.dart';
import 'view_manager_component.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A dedicated Nexus module for managing the application's view state.
class ViewManagerModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // Create the central entity that holds the current view state.
    final viewManager = Entity()
      ..add(TagsComponent({'view_manager'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(ViewStateComponent(currentView: AppView.customerList));
    world.addEntity(viewManager);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        // Provide the system that handles view change logic.
        _SingleSystemProvider([ViewManagerSystem()])
      ];
}
