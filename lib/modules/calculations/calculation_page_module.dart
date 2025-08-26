import 'package:nexus/nexus.dart';

/// A Nexus module that sets up the UI entity for the "Calculation" page.
class CalculationPageModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    final calculationPage = Entity()
      ..add(TagsComponent({'calculation_page'}))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(calculationPage);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [];
}
