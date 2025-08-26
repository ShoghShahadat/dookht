/// An event fired to request a change in the application's active theme.
/// The [ThemingSystem] listens for this event.
class ThemeChangedEvent {
  /// The unique identifier of the new theme to be activated (e.g., 'dark', 'sunrise').
  final String newThemeId;

  ThemeChangedEvent(this.newThemeId);
}
