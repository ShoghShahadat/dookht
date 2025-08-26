import 'package:flutter/material.dart';

/// A service class that provides the raw data for all available themes.
/// In a real app, this could be loaded from a JSON file or a remote server.
class ThemeProviderService {
  final Map<String, Map<String, dynamic>> _themes = {
    'light': {
      'isDarkMode': false,
      'gradient': [Colors.white.value, Colors.grey[200]!.value],
      'textColor': Colors.black.value,
      'cardColor': Colors.white.withOpacity(0.4).value,
      'borderColor': Colors.white.withOpacity(0.6).value,
    },
    'dark': {
      'isDarkMode': true,
      'gradient': [Color(0xFF232526).value, Color(0xFF414345).value],
      'textColor': Colors.white.value,
      'cardColor': Colors.white.withOpacity(0.1).value,
      'borderColor': Colors.white.withOpacity(0.2).value,
    },
    'sunrise': {
      'isDarkMode': false,
      'gradient': [Color(0xFFFF5F6D).value, Color(0xFFFFC371).value],
      'textColor': Colors.white.value,
      'cardColor': Colors.white.withOpacity(0.25).value,
      'borderColor': Colors.white.withOpacity(0.4).value,
    },
    'ocean': {
      'isDarkMode': true,
      'gradient': [Color(0xFF00c6ff).value, Color(0xFF0072ff).value],
      'textColor': Colors.white.value,
      'cardColor': Colors.white.withOpacity(0.2).value,
      'borderColor': Colors.white.withOpacity(0.3).value,
    },
  };

  /// Retrieves the properties for a given theme ID.
  /// Defaults to the 'dark' theme if the ID is not found.
  Map<String, dynamic> getThemeProperties(String themeId) {
    return _themes[themeId] ?? _themes['dark']!;
  }

  /// Returns a list of all available theme IDs.
  List<String> get availableThemes => _themes.keys.toList();
}
