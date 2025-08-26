import 'package:nexus/nexus.dart';

/// Event fired to navigate to the main customer list view.
class ShowCustomerListEvent {}

/// Event fired to show the form for adding a new customer.
class ShowAddCustomerFormEvent {}

/// Event fired to show the calculation page for a specific customer.
class ShowCalculationPageEvent {
  final EntityId customerId;
  ShowCalculationPageEvent(this.customerId);
}

/// Event fired when a new customer's data is submitted from the form.
class AddCustomerEvent {
  final String firstName;
  final String lastName;
  final String phone;

  AddCustomerEvent({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });
}

/// Event fired by the logic system after a customer has been successfully created and saved.
class CustomerAddedEvent {
  final EntityId customerId;
  CustomerAddedEvent(this.customerId);
}

/// Event fired to show the new method management/settings page.
class ShowMethodManagementEvent {}
