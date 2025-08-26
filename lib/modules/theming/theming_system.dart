import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart' hide ThemeChangedEvent, ThemeProviderService;
import 'package:nexus/src/components/decoration_components.dart';

import 'theme_changed_event.dart';
import 'theme_provider.dart';

/// The core system for managing and applying themes.
/// It listens for theme change events and updates all styleable entities accordingly.
class ThemingSystem extends System {
  late final ThemeProviderService _themeProvider;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    _themeProvider = services.get<ThemeProviderService>();
    listen<ThemeChangedEvent>(_onThemeChanged);
  }

  void _onThemeChanged(ThemeChangedEvent event) {
    // Find the central entity that holds the current theme state.
    final themeManager = world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('theme_manager') ?? false);

    if (themeManager == null) return;

    // 1. Update the central ThemeComponent with the new theme's data.
    final newThemeProperties =
        _themeProvider.getThemeProperties(event.newThemeId);
    themeManager.add(
        ThemeComponent(id: event.newThemeId, properties: newThemeProperties));

    // 2. Find all entities that can be styled.
    final styleableEntities =
        world.entities.values.where((e) => e.has<StyleableComponent>());

    // 3. Apply the new theme to each styleable entity.
    for (final entity in styleableEntities) {
      _applyThemeToEntity(entity, newThemeProperties);
    }
  }

  /// Applies theme properties to a single entity based on its style bindings.
  void _applyThemeToEntity(
      Entity entity, Map<String, dynamic> themeProperties) {
    final styleable = entity.get<StyleableComponent>()!;
    final currentDecoration =
        entity.get<DecorationComponent>() ?? DecorationComponent();

    // For now, we only handle the 'gradient' binding for the background.
    // This can be expanded to handle colors, text styles, etc.
    final gradientKey = styleable.styleBindings['gradient'];
    if (gradientKey != null) {
      final newGradientValue = themeProperties[gradientKey] as List<int>?;
      if (newGradientValue != null) {
        entity.add(DecorationComponent(
          // Create a GradientColor object for the decoration.
          color: GradientColor(
            colors: newGradientValue,
            stops: const [0.0, 1.0], // A simple two-color gradient
          ),
          // Preserve other decoration properties like box shadow.
          boxShadow: currentDecoration.boxShadow,
        ));
      }
    }
  }

  @override
  bool matches(Entity entity) => false; // This system is purely event-driven.

  @override
  void update(Entity entity, double dt) {}
}
