// FILE: lib/modules/ui/view_manager/view_manager_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: The event listener for `ShowVisualFormulaEditorEvent` now
// correctly sets both the `activeMethodId` and `activeFormulaKey`.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import '../../customers/customer_events.dart';
import 'view_manager_component.dart';

/// A system that manages the current visible view of the application.
class ViewManagerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ShowCustomerListEvent>((_) => _changeView(AppView.customerList));
    listen<ShowAddCustomerFormEvent>(
        (_) => _changeView(AppView.addCustomerForm));
    listen<ShowCalculationPageEvent>((event) =>
        _changeView(AppView.calculationPage, customerId: event.customerId));
    listen<ShowMethodManagementEvent>(
        (_) => _changeView(AppView.methodManagement));
    listen<ShowEditMethodEvent>(
        (event) => _changeView(AppView.editMethod, methodId: event.methodId));
    listen<ShowVisualFormulaEditorEvent>((event) => _changeView(
        AppView.visualFormulaEditor,
        methodId: event.methodId,
        formulaKey: event.formulaResultKey));
  }

  void _changeView(AppView view,
      {EntityId? customerId, EntityId? methodId, String? formulaKey}) {
    final viewManager = _getViewManagerEntity();
    if (viewManager != null) {
      final currentState = viewManager.get<ViewStateComponent>();
      viewManager.add(ViewStateComponent(
        currentView: view,
        activeCustomerId: customerId ?? currentState?.activeCustomerId,
        activeMethodId: methodId ?? currentState?.activeMethodId,
        activeFormulaKey: formulaKey ?? currentState?.activeFormulaKey,
      ));
    }
  }

  Entity? _getViewManagerEntity() {
    return world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('view_manager') ?? false);
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
