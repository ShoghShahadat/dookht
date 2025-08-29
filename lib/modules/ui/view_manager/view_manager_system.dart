// FILE: lib/modules/ui/view_manager/view_manager_system.dart
// (English comments for code clarity)

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import '../../customers/customer_events.dart';
import 'view_manager_component.dart';

/// A generic event to request a change of the main view.
class RequestViewChangeEvent {
  final AppView view;
  final EntityId? customerId;
  final EntityId? methodId;
  final String? formulaKey;

  RequestViewChangeEvent({
    required this.view,
    this.customerId,
    this.methodId,
    this.formulaKey,
  });
}

/// A system that manages the current visible view of the application.
class ViewManagerSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ShowCustomerListEvent>(
        (_) => _fireChangeEvent(AppView.customerList));
    listen<ShowAddCustomerFormEvent>(
        (_) => _fireChangeEvent(AppView.addCustomerForm));
    listen<ShowCalculationPageEvent>((event) => _fireChangeEvent(
        AppView.calculationPage,
        customerId: event.customerId));
    listen<ShowMethodManagementEvent>(
        (_) => _fireChangeEvent(AppView.methodManagement));
    listen<ShowEditMethodEvent>((event) =>
        _fireChangeEvent(AppView.editMethod, methodId: event.methodId));
    listen<ShowVisualFormulaEditorEvent>((event) => _fireChangeEvent(
        AppView.visualFormulaEditor,
        methodId: event.methodId,
        formulaKey: event.formulaResultKey));
  }

  void _fireChangeEvent(AppView view,
      {EntityId? customerId, EntityId? methodId, String? formulaKey}) {
    world.eventBus.fire(RequestViewChangeEvent(
      view: view,
      customerId: customerId,
      methodId: methodId,
      formulaKey: formulaKey,
    ));
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
