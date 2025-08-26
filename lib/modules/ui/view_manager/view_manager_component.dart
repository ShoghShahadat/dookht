import 'package:nexus/nexus.dart';

/// An enum representing the different primary views in the application.
enum AppView {
  customerList,
  addCustomerForm,
  calculationPage,
  methodManagement,
  editMethod, // The new view for editing a specific method
}

/// A serializable component that holds the current view state of the application.
class ViewStateComponent extends Component with SerializableComponent {
  final AppView currentView;
  final EntityId? activeCustomerId;
  // Store the ID of the method being edited.
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
