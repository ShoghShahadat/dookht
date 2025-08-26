import 'package:nexus/nexus.dart';
import 'models/pattern_method_model.dart';

// This module is responsible for loading all available pattern-making methods into the world.
class PatternMethodsModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // Create the default "Personal Method" entity.
    // In the future, other methods (like Muller, etc.) can be loaded here from a database or file.
    final personalMethod = Entity()
      ..add(TagsComponent({'pattern_method'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(PatternMethodComponent(
        methodId: 'personal_default',
        name: 'متد شخصی شما',
        variables: [
          DynamicVariable(key: 'ease', label: 'میزان آزادی', defaultValue: 1.0),
        ],
        formulas: [
          Formula(
              resultKey: 'bodiceBustWidth',
              expression: '({bustCircumference} / 4) + {ease}',
              label: 'عرض کادر سینه'),
          Formula(
              resultKey: 'bodiceWaistWidth',
              expression: '({waistCircumference} / 4)',
              label: 'عرض کادر کمر'),
          Formula(
              resultKey: 'bodiceHipWidth',
              expression: '({hipCircumference} / 4) + 2.0',
              label: 'عرض کادر باسن'),
          Formula(
              resultKey: 'frontInterscyeWidth',
              expression: '({frontInterscye} / 2) + 1.0',
              label: 'پهنای کارور جلو'),
          Formula(
              resultKey: 'backInterscyeWidth',
              expression: '({backInterscye} / 2) - 1.0',
              label: 'پهنای کارور پشت'),
          Formula(
              resultKey: 'sleeveWidth',
              expression: '({armCircumference} / 2) + 2.0',
              label: 'گشادی کف حلقه آستین'),
          Formula(
              resultKey: 'sleeveCuffWidth',
              expression: '({wristCircumference} / 2)',
              label: 'عرض مچ آستین'),
        ],
      ));

    world.addEntity(personalMethod);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [];
}
