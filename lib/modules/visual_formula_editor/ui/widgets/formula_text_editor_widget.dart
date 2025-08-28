// FILE: lib/modules/visual_formula_editor/ui/widgets/formula_text_editor_widget.dart
// (English comments for code clarity)
// MODIFIED v3.0: FINAL FIX - Implemented FocusNode to prevent cursor jumps
// while the user is actively typing.

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
  final FocusNode _focusNode = FocusNode(); // For tracking focus state
  Timer? _debounce;
  bool _isProgrammaticUpdate = false;

  @override
  void initState() {
    super.initState();
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .addListener(_onCanvasStateChanged);
    _focusNode.addListener(_onFocusChanged);
    _onCanvasStateChanged();
  }

  @override
  void didUpdateWidget(covariant FormulaTextEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editorEntityId != oldWidget.editorEntityId) {
      oldWidget.renderingSystem
          .getNotifier(oldWidget.editorEntityId)
          .removeListener(_onCanvasStateChanged);
      widget.renderingSystem
          .getNotifier(widget.editorEntityId)
          .addListener(_onCanvasStateChanged);
    }
  }

  void _onCanvasStateChanged() {
    // **MAJOR FIX**: Do not update the text field programmatically
    // if the user is currently focused on it. This prevents cursor jumps.
    if (_focusNode.hasFocus) {
      return;
    }

    final canvasState = widget.renderingSystem
        .get<EditorCanvasComponent>(widget.editorEntityId);
    if (canvasState == null) return;

    if (_controller.text != canvasState.currentExpression) {
      _isProgrammaticUpdate = true;
      _controller.text = canvasState.currentExpression;
    }
  }

  void _onFocusChanged() {
    // When the user unfocuses the text field, sync it with the canonical
    // expression from the graph one last time.
    if (!_focusNode.hasFocus) {
      _onCanvasStateChanged();
    }
  }

  void _onTextChanged(String value) {
    if (_isProgrammaticUpdate) {
      _isProgrammaticUpdate = false;
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      widget.renderingSystem.manager?.send(UpdateFormulaFromTextEvent(value));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
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
              focusNode: _focusNode, // Attach the focus node
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
