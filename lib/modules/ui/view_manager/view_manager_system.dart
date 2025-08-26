import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import '../../customers/customer_events.dart';
import 'view_manager_component.dart';

/// A system that manages the current visible view of the application.
/// It listens to navigation events and updates a central ViewStateComponent.
class ViewManagerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);

    // Ensure the central view manager entity exists.
    _ensureViewManagerEntity();

    // Listen for navigation events.
    listen<ShowCustomerListEvent>((_) => _changeView(AppView.customerList));
    listen<ShowAddCustomerFormEvent>(
        (_) => _changeView(AppView.addCustomerForm));
  }

  void _changeView(AppView view) {
    final viewManager = _getViewManagerEntity();
    if (viewManager != null) {
      viewManager.add(ViewStateComponent(currentView: view));
    }
  }

  Entity? _getViewManagerEntity() {
    return world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('view_manager') ?? false);
  }

  void _ensureViewManagerEntity() {
    if (_getViewManagerEntity() == null) {
      final viewManager = Entity()
        ..add(TagsComponent({'view_manager'}))
        ..add(LifecyclePolicyComponent(isPersistent: true))
        ..add(ViewStateComponent(currentView: AppView.customerList));
      world.addEntity(viewManager);
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
