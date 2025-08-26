import 'package:nexus/nexus.dart';

/// A serializable component that stores the final calculated dimensions for a pattern.
class CalculationResultComponent extends Component with SerializableComponent {
  // Bodice results
  final double? bodiceBustWidth; // 1/4 دور سینه + آزادی
  final double? bodiceWaistWidth; // 1/4 دور کمر
  final double? bodiceHipWidth; // 1/4 دور باسن + آزادی
  final double? frontInterscyeWidth; // 1/2 کارور جلو + اصلاح
  final double? backInterscyeWidth; // 1/2 کارور پشت - اصلاح

  // Sleeve results
  final double? sleeveWidth; // 1/2 دور بازو + آزادی
  final double? sleeveCuffWidth; // 1/2 دور مچ

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
