// FILE: lib/modules/ui/rendering_system.dart
// (English comments for code clarity)
// MODIFIED v8.0: All debug logs have been removed for a clean production-ready file.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/ui/edit_method_builder.dart';
import 'package:tailor_assistant/modules/method_management/ui/method_management_builder.dart';
import 'package:tailor_assistant/modules/ui/transitions/transition_component.dart';
import 'package:tailor_assistant/modules/ui/transitions/transition_painters.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/visual_formula_editor_builder.dart';

import '../calculations/ui/calculation_page_builder.dart';
import '../customers/ui/add_customer_form_builder.dart';
import '../customers/ui/customer_list_builder.dart';
import 'view_manager/view_manager_component.dart';

/// The main rendering system for the application.
class AppRenderingSystem extends FlutterRenderingSystem {
  final Map<AppView, IWidgetBuilder> _widgetBuilders = {
    AppView.customerList: CustomerListBuilder(),
    AppView.addCustomerForm: AddCustomerFormBuilder(),
    AppView.calculationPage: CalculationPageBuilder(),
    AppView.methodManagement: MethodManagementBuilder(),
    AppView.editMethod: EditMethodBuilder(),
    AppView.visualFormulaEditor: VisualFormulaEditorBuilder(),
  };

  @override
  Widget build(BuildContext context) {
    final viewManagerId = getAllIdsWithTag('view_manager').firstOrNull;
    return Scaffold(
      body: Stack(
        children: [
          if (viewManagerId != null) _buildMainView(context, viewManagerId),
        ],
      ),
    );
  }

  BoxDecoration _getGradientDecoration() {
    final backgroundId = getAllIdsWithTag('main_background').firstOrNull;
    if (backgroundId == null) {
      return const BoxDecoration(color: Colors.black);
    }
    final decoration = get<DecorationComponent>(backgroundId);
    final gradientColor = decoration?.color as GradientColor?;
    final colors = gradientColor?.colors.map((c) => Color(c)).toList() ??
        [Colors.black, Colors.black];

    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  Widget _buildMainView(BuildContext context, EntityId viewManagerId) {
    return AnimatedBuilder(
      animation: getNotifier(viewManagerId),
      builder: (context, _) {
        final viewState = get<ViewStateComponent>(viewManagerId);
        final transitionState = get<TransitionComponent>(viewManagerId);

        if (viewState == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final background = AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          decoration: _getGradientDecoration(),
        );

        if (transitionState?.isRunning == true) {
          final oldViewWidget =
              _buildViewFor(context, transitionState!.oldView);
          final newViewWidget = _buildViewFor(context, transitionState.newView);

          return Stack(
            children: [
              background,
              oldViewWidget,
              ClipPath(
                clipper: _getClipperForTransition(
                    transitionState.type, transitionState.progress),
                child: Container(
                  decoration: _getGradientDecoration(),
                  child: newViewWidget,
                ),
              ),
            ],
          );
        } else {
          return Stack(
            children: [
              background,
              _buildViewFor(context, viewState.currentView),
            ],
          );
        }
      },
    );
  }

  Widget _buildViewFor(BuildContext context, AppView view) {
    final builder = _widgetBuilders[view];
    if (builder == null) return const SizedBox.shrink();

    EntityId? entityId;
    switch (view) {
      case AppView.customerList:
        entityId = getAllIdsWithTag('customer_list_container').firstOrNull;
        break;
      case AppView.addCustomerForm:
        entityId = getAllIdsWithTag('add_customer_form').firstOrNull;
        break;
      case AppView.calculationPage:
        entityId = getAllIdsWithTag('calculation_page').firstOrNull;
        break;
      case AppView.methodManagement:
        entityId = getAllIdsWithTag('method_management_page').firstOrNull;
        break;
      case AppView.editMethod:
        entityId = getAllIdsWithTag('edit_method_page').firstOrNull;
        break;
      case AppView.visualFormulaEditor:
        entityId = getAllIdsWithTag('visual_formula_editor_page').firstOrNull;
        break;
    }

    if (entityId != null) {
      return KeyedSubtree(
        key: ValueKey(view.name),
        child: builder.build(context, this, entityId),
      );
    }
    return const SizedBox.shrink();
  }

  CustomClipper<Path> _getClipperForTransition(
      TransitionType type, double progress) {
    switch (type) {
      case TransitionType.watercolor:
        return WatercolorClipper(progress);
      case TransitionType.burnAway:
        return BurnAwayClipper(progress);
      case TransitionType.glitch:
        return GlitchClipper(progress);
      case TransitionType.pixelate:
        return InkSplashClipper(progress);
      case TransitionType.inkSplash:
        return InkSplashClipper(progress);
    }
  }
}
