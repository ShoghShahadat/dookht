// FILE: packages/nexus/lib/src/systems/theming_system.dart
// (English comments for code clarity)
// FINAL FIX v14: The system now correctly applies the initial theme upon
// being added to the world, ensuring the UI is styled correctly on startup
// without waiting for a theme change event.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/components/decoration_components.dart';
import 'package:nexus/src/events/theme_events.dart';
import 'package:nexus/src/components/styleable_component.dart';
import 'package:nexus/src/components/theme_component.dart';

// A mock service for providing theme data.
class ThemeProviderService {
  final Map<String, Map<String, dynamic>> _themes = {
    'light': {
      'primaryColor': 0xFF6200EE,
      'backgroundColor': 0xFFFFFFFF,
      'textColor': 0xFF000000,
      'shadowColor': 0x44000000,
      'gradient': [0xFFFFFFFF, 0xFFE0E0E0], // Example gradient
    },
    'dark': {
      'primaryColor': 0xFFBB86FC,
      'backgroundColor': 0xFF121212,
      'textColor': 0xFFFFFFFF,
      'shadowColor': 0x44FFFFFF,
      'gradient': [0xFF232526, 0xFF414345], // Example gradient
    },
  };

  Map<String, dynamic> getThemeProperties(String themeId) {
    return _themes[themeId] ?? _themes['dark']!;
  }
}

class ThemingSystem extends System {
  late final ThemeProviderService _themeProvider;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    if (!services.isRegistered<ThemeProviderService>()) {
      services.registerSingleton(ThemeProviderService());
    }
    _themeProvider = services.get<ThemeProviderService>();

    listen<ThemeChangedEvent>(_onThemeChanged);

    // THE FIX: Apply the initial theme as soon as the system is ready.
    Future.microtask(() => _applyCurrentTheme());
  }

  void _onThemeChanged(ThemeChangedEvent event) {
    final themeManager = _getThemeManager();
    if (themeManager == null) return;

    final newThemeProperties =
        _themeProvider.getThemeProperties(event.newThemeId);
    themeManager.add(
        ThemeComponent(id: event.newThemeId, properties: newThemeProperties));

    _applyThemeToEntity(themeManager, newThemeProperties);
  }

  void _applyCurrentTheme() {
    final themeManager = _getThemeManager();
    if (themeManager == null) return;

    final currentTheme = themeManager.get<ThemeComponent>();
    if (currentTheme == null) return;

    _applyThemeToEntity(themeManager, currentTheme.properties);
  }

  void _applyThemeToEntity(
      Entity themeManager, Map<String, dynamic> themeProperties) {
    final styleableEntities =
        world.entities.values.where((e) => e.has<StyleableComponent>());

    for (final entity in styleableEntities) {
      final styleable = entity.get<StyleableComponent>()!;
      final currentDecoration =
          entity.get<DecorationComponent>() ?? DecorationComponent();

      // This logic can be expanded to handle all bindings.
      final gradientKey = styleable.styleBindings['gradient'];
      if (gradientKey != null) {
        final newGradientValue =
            (themeProperties[gradientKey] as List?)?.cast<int>();
        if (newGradientValue != null) {
          entity.add(DecorationComponent(
            color: GradientColor(
              colors: newGradientValue,
              stops: const [0.0, 1.0],
            ),
            boxShadow: currentDecoration.boxShadow,
          ));
        }
      }
    }
  }

  Entity? _getThemeManager() {
    // It's safer to look for the theme_manager tag.
    return world.entities.values.firstWhereOrNull(
        (e) => e.get<TagsComponent>()?.hasTag('theme_manager') ?? false);
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
