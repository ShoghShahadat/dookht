import 'package:nexus/nexus.dart';

/// A serializable data component that holds the information for a single customer.
class CustomerComponent extends Component with SerializableComponent {
  final String firstName;
  final String lastName;
  final String phone;

  CustomerComponent({
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  factory CustomerComponent.fromJson(Map<String, dynamic> json) {
    return CustomerComponent(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
      };

  @override
  List<Object?> get props => [firstName, lastName, phone];
}
