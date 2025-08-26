import 'package:nexus/nexus.dart' hide ThemeProviderService, ThemeChangedEvent;
import 'package:get_it/get_it.dart';
import '../../theming/theme_changed_event.dart';
import '../../theming/theme_provider.dart';

/// A Nexus module that creates the UI entities for the theme selector.
class ThemeSelectorModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    final themeProvider = GetIt.instance<ThemeProviderService>();
    final availableThemes = themeProvider.availableThemes;

    final buttonEntities = <EntityId>[];

    // Create a button entity for each available theme.
    for (final themeId in availableThemes) {
      final themeProperties = themeProvider.getThemeProperties(themeId);
      final gradientColors =
          (themeProperties['gradient'] as List<dynamic>).cast<int>();

      final buttonEntity = Entity()
        ..add(TagsComponent({'theme_button', themeId}))
        ..add(LifecyclePolicyComponent(isPersistent: true))
        // This component holds the data needed to render the button.
        ..add(CustomWidgetComponent(
          widgetType: 'theme_swatch',
          properties: {
            'gradient': gradientColors,
            'id': themeId,
          },
        ))
        // When tapped, this entity will fire an event to change the theme.
        ..add(ClickableComponent((entity) {
          world.eventBus.fire(ThemeChangedEvent(themeId));
        }));

      world.addEntity(buttonEntity);
      buttonEntities.add(buttonEntity.id);
    }

    // Create a container entity to hold all the buttons.
    // The rendering system will find this container to build the UI.
    final containerEntity = Entity()
      ..add(TagsComponent({'theme_selector_container'}))
      ..add(LifecyclePolicyComponent(isPersistent: true))
      ..add(ChildrenComponent(buttonEntities));

    world.addEntity(containerEntity);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [];
}
