import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/ui/method_management_builder.dart';

import '../calculations/ui/calculation_page_builder.dart';
import '../customers/ui/add_customer_form_builder.dart';
import '../customers/ui/customer_list_builder.dart';
import 'theme_selector/theme_selector_builder.dart';
import 'view_manager/view_manager_component.dart';

/// The main rendering system for the application.
/// It acts as a director, deciding which IWidgetBuilder to use based on the current view state.
class AppRenderingSystem extends FlutterRenderingSystem {
  final Map<String, IWidgetBuilder> _widgetBuilders = {
    'theme_selector': ThemeSelectorBuilder(),
    'customer_list': CustomerListBuilder(),
    'add_customer_form': AddCustomerFormBuilder(),
    'calculation_page': CalculationPageBuilder(),
    'method_management': MethodManagementBuilder(), // Register the new builder
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
              if (viewManagerId != null) _buildMainView(context, viewManagerId),
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

        switch (currentView) {
          case AppView.customerList:
            final id = getAllIdsWithTag('customer_list_container').firstOrNull;
            if (id != null) {
              return _widgetBuilders['customer_list']!.build(context, this, id);
            }
          case AppView.addCustomerForm:
            final id = getAllIdsWithTag('add_customer_form').firstOrNull;
            if (id != null) {
              return _widgetBuilders['add_customer_form']!
                  .build(context, this, id);
            }
          case AppView.calculationPage:
            final id = getAllIdsWithTag('calculation_page').firstOrNull;
            if (id != null) {
              return _widgetBuilders['calculation_page']!
                  .build(context, this, id);
            }
          // Add the case for the new method management page.
          case AppView.methodManagement:
            final id = getAllIdsWithTag('method_management_page').firstOrNull;
            if (id != null) {
              return _widgetBuilders['method_management']!
                  .build(context, this, id);
            }
        }
        return const Center(child: CircularProgressIndicator());
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
