// FILE: lib/modules/ui/view_manager/view_manager_system.dart
// (English comments for code clarity)
// MODIFIED v3.0: Added specialized logging.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
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
    listen<ShowCustomerListEvent>((event) {
      debugPrint(
          "[LOG | ViewManagerSystem] --> Received ShowCustomerListEvent.");
      _fireChangeEvent(AppView.customerList);
    });
    listen<ShowAddCustomerFormEvent>((event) {
      debugPrint(
          "[LOG | ViewManagerSystem] --> Received ShowAddCustomerFormEvent.");
      _fireChangeEvent(AppView.addCustomerForm);
    });
    listen<ShowCalculationPageEvent>((event) {
      debugPrint(
          "[LOG | ViewManagerSystem] --> Received ShowCalculationPageEvent for customer ${event.customerId}.");
      _fireChangeEvent(AppView.calculationPage, customerId: event.customerId);
    });
    listen<ShowMethodManagementEvent>((event) {
      debugPrint(
          "[LOG | ViewManagerSystem] --> Received ShowMethodManagementEvent.");
      _fireChangeEvent(AppView.methodManagement);
    });
    listen<ShowEditMethodEvent>((event) {
      debugPrint(
          "[LOG | ViewManagerSystem] --> Received ShowEditMethodEvent for method ${event.methodId}.");
      _fireChangeEvent(AppView.editMethod, methodId: event.methodId);
    });
    listen<ShowVisualFormulaEditorEvent>((event) {
      debugPrint(
          "[LOG | ViewManagerSystem] --> Received ShowVisualFormulaEditorEvent for method ${event.methodId}.");
      _fireChangeEvent(AppView.visualFormulaEditor,
          methodId: event.methodId, formulaKey: event.formulaResultKey);
    });
  }

  void _fireChangeEvent(AppView view,
      {EntityId? customerId, EntityId? methodId, String? formulaKey}) {
    debugPrint(
        "[LOG | ViewManagerSystem] <-- Firing RequestViewChangeEvent for view: ${view.name}.");
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
