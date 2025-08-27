// FILE: lib/modules/customers/components/measurement_component.dart
// (English comments for code clarity)
// FINAL FIX v7: Added a static, stable typeId for robust serialization.

import 'package:nexus/nexus.dart';

class MeasurementComponent extends Component with SerializableComponent {
  static const String typeId = 'measurement';

  // Main body measurements
  final double? bustCircumference; // دور سینه
  final double? waistCircumference; // دور کمر
  final double? hipCircumference; // دور باسن

  // Width measurements
  final double? frontInterscye; // کارور جلو
  final double? backInterscye; // کارور پشت

  // Length measurements
  final double? torsoHeight; // قد بالاتنه
  final double? hipHeight; // بلندی باسن

  // Sleeve measurements
  final double? sleeveLength; // قد آستین
  final double? armCircumference; // دور بازو
  final double? wristCircumference; // دور مچ

  MeasurementComponent({
    this.bustCircumference,
    this.waistCircumference,
    this.hipCircumference,
    this.frontInterscye,
    this.backInterscye,
    this.torsoHeight,
    this.hipHeight,
    this.sleeveLength,
    this.armCircumference,
    this.wristCircumference,
  });

  factory MeasurementComponent.fromJson(Map<String, dynamic> json) {
    return MeasurementComponent(
      bustCircumference: (json['bustCircumference'] as num?)?.toDouble(),
      waistCircumference: (json['waistCircumference'] as num?)?.toDouble(),
      hipCircumference: (json['hipCircumference'] as num?)?.toDouble(),
      frontInterscye: (json['frontInterscye'] as num?)?.toDouble(),
      backInterscye: (json['backInterscye'] as num?)?.toDouble(),
      torsoHeight: (json['torsoHeight'] as num?)?.toDouble(),
      hipHeight: (json['hipHeight'] as num?)?.toDouble(),
      sleeveLength: (json['sleeveLength'] as num?)?.toDouble(),
      armCircumference: (json['armCircumference'] as num?)?.toDouble(),
      wristCircumference: (json['wristCircumference'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'bustCircumference': bustCircumference,
        'waistCircumference': waistCircumference,
        'hipCircumference': hipCircumference,
        'frontInterscye': frontInterscye,
        'backInterscye': backInterscye,
        'torsoHeight': torsoHeight,
        'hipHeight': hipHeight,
        'sleeveLength': sleeveLength,
        'armCircumference': armCircumference,
        'wristCircumference': wristCircumference,
      };

  @override
  List<Object?> get props => [
        bustCircumference,
        waistCircumference,
        hipCircumference,
        frontInterscye,
        backInterscye,
        torsoHeight,
        hipHeight,
        sleeveLength,
        armCircumference,
        wristCircumference
      ];
}
