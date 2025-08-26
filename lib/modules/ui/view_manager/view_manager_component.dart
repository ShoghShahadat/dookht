import 'package:nexus/nexus.dart';

/// An enum representing the different primary views in the application.
enum AppView {
  customerList,
  addCustomerForm,
  calculationPage, // The new view for the calculation screen
}

/// A serializable component that holds the current view state of the application.
class ViewStateComponent extends Component with SerializableComponent {
  final AppView currentView;
  // Store the ID of the customer whose calculation page is being viewed.
  final EntityId? activeCustomerId;

  ViewStateComponent({
    this.currentView = AppView.customerList,
    this.activeCustomerId,
  });

  factory ViewStateComponent.fromJson(Map<String, dynamic> json) {
    return ViewStateComponent(
      currentView: AppView.values[json['currentView'] as int],
      activeCustomerId: json['activeCustomerId'] as EntityId?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'currentView': currentView.index,
        'activeCustomerId': activeCustomerId,
      };

  @override
  List<Object?> get props => [currentView, activeCustomerId];
}
