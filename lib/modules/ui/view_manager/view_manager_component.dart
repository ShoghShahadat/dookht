// FILE: lib/modules/ui/view_manager/view_manager_component.dart
// (English comments for code clarity)
// FINAL FIX v7: Added a static, stable typeId for robust serialization.

import 'package:nexus/nexus.dart';

enum AppView {
  customerList,
  addCustomerForm,
  calculationPage,
  methodManagement,
  editMethod,
}

class ViewStateComponent extends Component with SerializableComponent {
  static const String typeId = 'view_state';

  final AppView currentView;
  final EntityId? activeCustomerId;
  final EntityId? activeMethodId;

  ViewStateComponent({
    this.currentView = AppView.customerList,
    this.activeCustomerId,
    this.activeMethodId,
  });

  factory ViewStateComponent.fromJson(Map<String, dynamic> json) {
    return ViewStateComponent(
      currentView: AppView.values[json['currentView'] as int],
      activeCustomerId: json['activeCustomerId'] as EntityId?,
      activeMethodId: json['activeMethodId'] as EntityId?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'currentView': currentView.index,
        'activeCustomerId': activeCustomerId,
        'activeMethodId': activeMethodId,
      };

  @override
  List<Object?> get props => [currentView, activeCustomerId, activeMethodId];
}
