import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import '../rendering_system.dart';

/// A dedicated widget builder for rendering the theme selector UI.
class ThemeSelectorBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    final childrenComp = rs.get<ChildrenComponent>(entityId);
    if (childrenComp == null || childrenComp.children.isEmpty) {
      return const SizedBox.shrink();
    }

    final themeManagerId = rs.getAllIdsWithTag('theme_manager').firstOrNull;
    if (themeManagerId == null) return const SizedBox.shrink();

    // Use AnimatedBuilder to listen to changes on the theme_manager entity.
    return AnimatedBuilder(
      animation: rs.getNotifier(themeManagerId),
      builder: (context, _) {
        final currentTheme = rs.get<ThemeComponent>(themeManagerId);

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: childrenComp.children.map((buttonId) {
            return _buildThemeButton(context, rs, buttonId, currentTheme?.id);
          }).toList(),
        );
      },
    );
  }

  Widget _buildThemeButton(BuildContext context, FlutterRenderingSystem rs,
      EntityId buttonId, String? currentThemeId) {
    final customWidget = rs.get<CustomWidgetComponent>(buttonId);
    final properties = customWidget?.properties ?? {};
    final gradientColors =
        (properties['gradient'] as List<dynamic>?)?.cast<int>() ?? [0, 0];
    final themeId = properties['id'] as String?;
    final isActive = themeId == currentThemeId;

    return GestureDetector(
      onTap: () {
        // Send a tap event to the logic isolate.
        rs.manager?.send(EntityTapEvent(buttonId));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: gradientColors.map((c) => Color(c)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            width: isActive ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 1,
            )
          ],
        ),
        child: isActive
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }
}
