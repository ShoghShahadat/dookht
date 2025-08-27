// FILE: lib/modules/customers/components/customer_component.dart
// (English comments for code clarity)
// FINAL FIX v7: Added a static, stable typeId for robust serialization.

import 'package:nexus/nexus.dart';

class CustomerComponent extends Component with SerializableComponent {
  // Static, constant type identifier. This will not be changed by minification.
  static const String typeId = 'customer';

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
