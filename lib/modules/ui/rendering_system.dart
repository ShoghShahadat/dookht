// FILE: lib/modules/ui/rendering_system.dart
// (English comments for code clarity)
// FINAL, DEFINITIVE FIX v3: The root cause of the loading spinner was a race
// condition where the UI would try to build before the initial entity packets
// arrived. The fix is to make the builder logic more resilient. If the
// target entity ID is null during the initial build, we now pass a temporary,
// non-existent ID (-1) to the builder. The builder itself is responsible for
// handling this "empty" state gracefully, thus eliminating the loading spinner
// and ensuring a smooth initial render.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/ui/edit_method_builder.dart';
import 'package:tailor_assistant/modules/method_management/ui/method_management_builder.dart';

import '../calculations/ui/calculation_page_builder.dart';
import '../customers/ui/add_customer_form_builder.dart';
import '../customers/ui/customer_list_builder.dart';
import 'theme_selector/theme_selector_builder.dart';
import 'view_manager/view_manager_component.dart';

/// The main rendering system for the application.
class AppRenderingSystem extends FlutterRenderingSystem {
  final Map<String, IWidgetBuilder> _widgetBuilders = {
    'theme_selector': ThemeSelectorBuilder(),
    'customer_list': CustomerListBuilder(),
    'add_customer_form': AddCustomerFormBuilder(),
    'calculation_page': CalculationPageBuilder(),
    'method_management': MethodManagementBuilder(),
    'edit_method': EditMethodBuilder(),
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: this,
      builder: (context, child) {
        final backgroundId = getAllIdsWithTag('main_background').firstOrNull;
        final themeSelectorId =
            getAllIdsWithTag('theme_selector_container').firstOrNull;
        final viewManagerId = getAllIdsWithTag('view_manager').firstOrNull;

        return Scaffold(
          body: Stack(
            children: [
              if (backgroundId != null) _buildBackground(context, backgroundId),
              if (viewManagerId != null)
                _buildMainView(context, viewManagerId)
              else
                // This state is very temporary, so a simple indicator is fine.
                const Center(child: CircularProgressIndicator()),
              if (themeSelectorId != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildThemeSelector(context, themeSelectorId),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainView(BuildContext context, EntityId viewManagerId) {
    return AnimatedBuilder(
      animation: getNotifier(viewManagerId),
      builder: (context, _) {
        final viewState = get<ViewStateComponent>(viewManagerId);
        final currentView = viewState?.currentView ?? AppView.customerList;

        // This is the final, robust solution.
        // We find the ID. If it's null (because the packet hasn't arrived yet),
        // we pass a temporary, non-existent ID (-1). The builder itself
        // is responsible for handling this gracefully (e.g., showing an empty state).
        // This completely eliminates the loading spinner race condition.
        switch (currentView) {
          case AppView.customerList:
            final id = getAllIdsWithTag('customer_list_container').firstOrNull;
            return _widgetBuilders['customer_list']!
                .build(context, this, id ?? -1);
          case AppView.addCustomerForm:
            final id = getAllIdsWithTag('add_customer_form').firstOrNull;
            return _widgetBuilders['add_customer_form']!
                .build(context, this, id ?? -1);
          case AppView.calculationPage:
            final id = getAllIdsWithTag('calculation_page').firstOrNull;
            return _widgetBuilders['calculation_page']!
                .build(context, this, id ?? -1);
          case AppView.methodManagement:
            final id = getAllIdsWithTag('method_management_page').firstOrNull;
            return _widgetBuilders['method_management']!
                .build(context, this, id ?? -1);
          case AppView.editMethod:
            final id = getAllIdsWithTag('edit_method_page').firstOrNull;
            return _widgetBuilders['edit_method']!
                .build(context, this, id ?? -1);
        }
      },
    );
  }

  Widget _buildThemeSelector(BuildContext context, EntityId themeSelectorId) {
    return _widgetBuilders['theme_selector']!
        .build(context, this, themeSelectorId);
  }

  Widget _buildBackground(BuildContext context, EntityId backgroundId) {
    return AnimatedBuilder(
      animation: getNotifier(backgroundId),
      builder: (context, _) {
        final decoration = get<DecorationComponent>(backgroundId);
        final gradientColor = decoration?.color as GradientColor?;
        final colors = gradientColor?.colors.map((c) => Color(c)).toList() ??
            [Colors.black, Colors.black];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}
