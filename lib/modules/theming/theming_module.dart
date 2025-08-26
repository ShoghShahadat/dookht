import 'package:nexus/nexus.dart' hide ThemingSystem, ThemeProviderService;
import 'package:get_it/get_it.dart';

import 'theme_provider.dart';
import 'theming_system.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A Nexus module responsible for setting up and managing the application's theme.
class ThemingModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // Service registration is now handled in the isolateInitializer,
    // so we can remove it from here to avoid confusion.
    final themeProvider = GetIt.instance<ThemeProviderService>();

    // Create a central entity to hold the current theme state.
    final themeEntity = Entity()
      ..add(TagsComponent({'theme_manager'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      // Initialize with the 'dark' theme by default.
      ..add(ThemeComponent(
          id: 'dark', properties: themeProvider.getThemeProperties('dark')));

    world.addEntity(themeEntity);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        _SingleSystemProvider([ThemingSystem()])
      ];
}
