import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import '../../customers/customer_events.dart';
import 'view_manager_component.dart';

/// A system that manages the current visible view of the application.
class ViewManagerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    debugPrint("👂 [ViewManagerSystem] Now listening for navigation events.");
    listen<ShowCustomerListEvent>((_) => _changeView(AppView.customerList));
    listen<ShowAddCustomerFormEvent>(
        (_) => _changeView(AppView.addCustomerForm));
    listen<ShowCalculationPageEvent>((event) =>
        _changeView(AppView.calculationPage, customerId: event.customerId));
    listen<ShowMethodManagementEvent>(
        (_) => _changeView(AppView.methodManagement));
    // Listen for the event to show the edit method page.
    listen<ShowEditMethodEvent>(
        (event) => _changeView(AppView.editMethod, methodId: event.methodId));
  }

  void _changeView(AppView view, {EntityId? customerId, EntityId? methodId}) {
    debugPrint("🔄 [ViewManagerSystem] Changing view to: $view");
    final viewManager = _getViewManagerEntity();
    if (viewManager != null) {
      viewManager.add(ViewStateComponent(
        currentView: view,
        activeCustomerId: customerId,
        activeMethodId: methodId,
      ));
    } else {
      debugPrint("  - ❌ ERROR: Could not find 'view_manager' entity!");
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
