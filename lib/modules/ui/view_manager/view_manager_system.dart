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
    listen<ShowCalculationPageEvent>((event) =>
        _changeView(AppView.calculationPage, customerId: event.customerId));
    // Listen for the event to show the method management page.
    listen<ShowMethodManagementEvent>(
        (_) => _changeView(AppView.methodManagement));
  }

  void _changeView(AppView view, {EntityId? customerId}) {
    final viewManager = _getViewManagerEntity();
    if (viewManager != null) {
      // When navigating away from calculation page, clear the active customer id
      final newCustomerId =
          (view == AppView.calculationPage) ? customerId : null;
      viewManager.add(ViewStateComponent(
        currentView: view,
        activeCustomerId: newCustomerId,
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
