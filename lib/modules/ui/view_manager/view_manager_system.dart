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
    listen<ShowCustomerListEvent>((_) => _changeView(AppView.customerList));
    listen<ShowAddCustomerFormEvent>(
        (_) => _changeView(AppView.addCustomerForm));
    // Listen for the event to show the calculation page.
    listen<ShowCalculationPageEvent>((event) =>
        _changeView(AppView.calculationPage, customerId: event.customerId));
  }

  void _changeView(AppView view, {EntityId? customerId}) {
    final viewManager = _getViewManagerEntity();
    if (viewManager != null) {
      viewManager.add(ViewStateComponent(
        currentView: view,
        activeCustomerId: customerId,
      ));
    }
  }

  Entity? _getViewManagerEntity() {
    return world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('view_manager') ?? false);
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
