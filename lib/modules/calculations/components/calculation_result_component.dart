// FILE: lib/modules/calculations/components/calculation_result_component.dart
// (English comments for code clarity)
// FINAL FIX v7: Added a static, stable typeId for robust serialization.

import 'package:nexus/nexus.dart';

class CalculationResultComponent extends Component with SerializableComponent {
  static const String typeId = 'calculation_result';

  // Bodice results
  final double? bodiceBustWidth;
  final double? bodiceWaistWidth;
  final double? bodiceHipWidth;
  final double? frontInterscyeWidth;
  final double? backInterscyeWidth;

  // Sleeve results
  final double? sleeveWidth;
  final double? sleeveCuffWidth;

  CalculationResultComponent({
    this.bodiceBustWidth,
    this.bodiceWaistWidth,
    this.bodiceHipWidth,
    this.frontInterscyeWidth,
    this.backInterscyeWidth,
    this.sleeveWidth,
    this.sleeveCuffWidth,
  });

  factory CalculationResultComponent.fromJson(Map<String, dynamic> json) {
    return CalculationResultComponent(
      bodiceBustWidth: (json['bodiceBustWidth'] as num?)?.toDouble(),
      bodiceWaistWidth: (json['bodiceWaistWidth'] as num?)?.toDouble(),
      bodiceHipWidth: (json['bodiceHipWidth'] as num?)?.toDouble(),
      frontInterscyeWidth: (json['frontInterscyeWidth'] as num?)?.toDouble(),
      backInterscyeWidth: (json['backInterscyeWidth'] as num?)?.toDouble(),
      sleeveWidth: (json['sleeveWidth'] as num?)?.toDouble(),
      sleeveCuffWidth: (json['sleeveCuffWidth'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'bodiceBustWidth': bodiceBustWidth,
        'bodiceWaistWidth': bodiceWaistWidth,
        'bodiceHipWidth': bodiceHipWidth,
        'frontInterscyeWidth': frontInterscyeWidth,
        'backInterscyeWidth': backInterscyeWidth,
        'sleeveWidth': sleeveWidth,
        'sleeveCuffWidth': sleeveCuffWidth,
      };

  @override
  List<Object?> get props => [
        bodiceBustWidth,
        bodiceWaistWidth,
        bodiceHipWidth,
        frontInterscyeWidth,
        backInterscyeWidth,
        sleeveWidth,
        sleeveCuffWidth
      ];
}
