// FILE: lib/modules/ui/view_manager/view_manager_component.dart
// (English comments for code clarity)
// MODIFIED v2.0: Added `activeFormulaKey` to track which specific formula
// is being edited in the visual editor.

import 'package:nexus/nexus.dart';

/// An enum representing the different primary views in the application.
enum AppView {
  customerList,
  addCustomerForm,
  calculationPage,
  methodManagement,
  editMethod,
  visualFormulaEditor,
}

/// A serializable component that holds the current view state of the application.
class ViewStateComponent extends Component with SerializableComponent {
  final AppView currentView;
  final EntityId? activeCustomerId;
  final EntityId? activeMethodId;
  final String? activeFormulaKey; // NEW: e.g., 'bodiceBustWidth'

  ViewStateComponent({
    this.currentView = AppView.customerList,
    this.activeCustomerId,
    this.activeMethodId,
    this.activeFormulaKey,
  });

  factory ViewStateComponent.fromJson(Map<String, dynamic> json) {
    return ViewStateComponent(
      currentView: AppView.values[json['currentView'] as int],
      activeCustomerId: json['activeCustomerId'] as EntityId?,
      activeMethodId: json['activeMethodId'] as EntityId?,
      activeFormulaKey: json['activeFormulaKey'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'currentView': currentView.index,
        'activeCustomerId': activeCustomerId,
        'activeMethodId': activeMethodId,
        'activeFormulaKey': activeFormulaKey,
      };

  @override
  List<Object?> get props =>
      [currentView, activeCustomerId, activeMethodId, activeFormulaKey];
}
