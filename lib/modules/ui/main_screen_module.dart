import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/decoration_components.dart';

/// A Nexus module for creating the initial UI entities of the main screen.
class MainScreenModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // Create the main background entity.
    // This entity will hold the data for our glassmorphism background.
    final backgroundEntity = Entity()
      ..add(TagsComponent({'main_background'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      // The StyleableComponent links this entity's decoration to the central theme.
      ..add(StyleableComponent(styleBindings: {
        // Bind the 'gradient' property of this entity's decoration
        // to the 'gradient' property of the active theme.
        'gradient': 'gradient',
      }))
      // Initialize with an empty decoration. The ThemingSystem will populate it.
      ..add(DecorationComponent());

    world.addEntity(backgroundEntity);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [];
}
