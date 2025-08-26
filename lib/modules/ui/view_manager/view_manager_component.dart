import 'package:nexus/nexus.dart';

/// An enum representing the different primary views in the application.
enum AppView {
  customerList,
  addCustomerForm,
}

/// A serializable component that holds the current view state of the application.
/// This is typically attached to a central 'view_manager' entity.
class ViewStateComponent extends Component with SerializableComponent {
  final AppView currentView;

  ViewStateComponent({this.currentView = AppView.customerList});

  factory ViewStateComponent.fromJson(Map<String, dynamic> json) {
    return ViewStateComponent(
      currentView: AppView.values[json['currentView'] as int],
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'currentView': currentView.index,
      };

  @override
  List<Object?> get props => [currentView];
}
