// FILE: lib/modules/ui/rendering_system.dart
// (English comments for code clarity)
// FINAL FIX v4.0: Re-introduced the 'hide' directive. The compiler errors confirm
// that there is a name collision with 'EditMethodBuilder' in one of the imported
// files. Hiding it from the 'method_management_builder' import is the correct
// and definitive solution to resolve this ambiguity.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/ui/edit_method_builder.dart';
// The 'hide' keyword resolves the name conflict for EditMethodBuilder.
import 'package:tailor_assistant/modules/method_management/ui/method_management_builder.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/visual_formula_editor_builder.dart';

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
    'visual_formula_editor': VisualFormulaEditorBuilder(),
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
            break;
          case AppView.addCustomerForm:
            final id = getAllIdsWithTag('add_customer_form').firstOrNull;
            if (id != null) {
              return _widgetBuilders['add_customer_form']!
                  .build(context, this, id);
            }
            break;
          case AppView.calculationPage:
            final id = getAllIdsWithTag('calculation_page').firstOrNull;
            if (id != null) {
              return _widgetBuilders['calculation_page']!
                  .build(context, this, id);
            }
            break;
          case AppView.methodManagement:
            final id = getAllIdsWithTag('method_management_page').firstOrNull;
            if (id != null) {
              return _widgetBuilders['method_management']!
                  .build(context, this, id);
            }
            break;
          case AppView.editMethod:
            final id = getAllIdsWithTag('edit_method_page').firstOrNull;
            if (id != null) {
              return _widgetBuilders['edit_method']!.build(context, this, id);
            }
            break;
          case AppView.visualFormulaEditor:
            final id =
                getAllIdsWithTag('visual_formula_editor_page').firstOrNull;
            if (id != null) {
              return _widgetBuilders['visual_formula_editor']!
                  .build(context, this, id);
            }
            break;
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
