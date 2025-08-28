// FILE: lib/modules/visual_formula_editor/ui/widgets/formula_text_editor_widget.dart
// (English comments for code clarity)
// NEW FILE: This widget provides the live text editor for the formula.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

class FormulaTextEditorWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId editorEntityId;

  const FormulaTextEditorWidget({
    super.key,
    required this.renderingSystem,
    required this.editorEntityId,
  });

  @override
  State<FormulaTextEditorWidget> createState() =>
      _FormulaTextEditorWidgetState();
}

class _FormulaTextEditorWidgetState extends State<FormulaTextEditorWidget> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Listen for changes from the logic world to update the text field
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .addListener(_onCanvasStateChanged);
    _onCanvasStateChanged(); // Initial sync
  }

  void _onCanvasStateChanged() {
    final canvasState = widget.renderingSystem
        .get<EditorCanvasComponent>(widget.editorEntityId);
    if (canvasState == null) return;

    // Update the text field only if the text is different, to avoid cursor jumps
    if (_controller.text != canvasState.currentExpression) {
      _controller.text = canvasState.currentExpression;
    }
  }

  void _onTextChanged(String value) {
    // Debounce the event to avoid flooding the logic isolate while typing
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      widget.renderingSystem.manager?.send(UpdateFormulaFromTextEvent(value));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .removeListener(_onCanvasStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'فرمول متنی',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
