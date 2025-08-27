// FILE: lib/modules/visual_formula_editor/ui/visual_formula_editor_builder.dart
// (English comments for code clarity)

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import '../../ui/rendering_system.dart';

class VisualFormulaEditorBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    final viewManagerId = rs.getAllIdsWithTag('view_manager').firstOrNull;
    if (viewManagerId == null) return const SizedBox.shrink();

    final viewState = rs.get<ViewStateComponent>(viewManagerId);
    final activeMethodId = viewState?.activeMethodId;
    if (activeMethodId == null) {
      return const Center(
          child: Text('No method selected for visual editing.'));
    }

    return _VisualFormulaEditorWidget(
      renderingSystem: rs,
      methodId: activeMethodId,
    );
  }
}

class _VisualFormulaEditorWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId methodId;

  const _VisualFormulaEditorWidget(
      {required this.renderingSystem, required this.methodId});

  @override
  State<_VisualFormulaEditorWidget> createState() =>
      _VisualFormulaEditorWidgetState();
}

class _VisualFormulaEditorWidgetState
    extends State<_VisualFormulaEditorWidget> {
  Color _getTextColor() {
    final rs = widget.renderingSystem;
    final themeManagerId = rs.getAllIdsWithTag('theme_manager').firstOrNull;
    if (themeManagerId == null) return Colors.white;
    final themeComp = rs.get<ThemeComponent>(themeManagerId);
    return Color(themeComp?.properties['textColor'] as int? ?? 0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final method =
        widget.renderingSystem.get<PatternMethodComponent>(widget.methodId);
    if (method == null) {
      return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Method not found!')));
    }
    final textColor = _getTextColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('طراحی گرافیکی: ${method.name}',
            style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () =>
              widget.renderingSystem.manager?.send(ShowMethodManagementEvent()),
        ),
      ),
      body: Stack(
        children: [
          // The main canvas for drawing nodes and connections
          CustomPaint(
            painter: _FormulaCanvasPainter(),
            child: Container(),
          ),
          // UI elements like toolbars and property panels will go here
        ],
      ),
    );
  }
}

// The CustomPainter that will render our formula graph.
class _FormulaCanvasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Placeholder background
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.2);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Placeholder text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'بوم ویرایشگر فرمول\n(در حال ساخت...)',
        style: TextStyle(color: Colors.white54, fontSize: 24),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    final offset = Offset((size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // For now, no need to repaint
  }
}
