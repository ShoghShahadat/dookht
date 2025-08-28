// FILE: lib/modules/visual_formula_editor/ui/widgets/formula_text_editor_widget.dart
// (English comments for code clarity)
// MODIFIED v8.0: CRITICAL FIX - Resolved the RangeError crash by clamping
// the selection offset before using it in the substring method. This ensures
// the painter can gracefully handle invalid selection states (like -1) during
// initial widget builds without throwing an exception.

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

// --- Helper classes for Syntax Highlighting ---

enum TokenType { variable, number, operator, whitespace, unknown }

class Token {
  final String text;
  final TokenType type;
  Token(this.text, this.type);
}

// --- Main Custom Editor Widget ---

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
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  Timer? _cursorTimer;
  bool _cursorVisible = true;
  bool _isProgrammaticUpdate = false;

  @override
  void initState() {
    super.initState();
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .addListener(_onCanvasStateChanged);
    _controller.addListener(() {
      setState(() {});
    });
    _focusNode.addListener(_onFocusChanged);
    _onCanvasStateChanged();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cursorTimer?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    widget.renderingSystem
        .getNotifier(widget.editorEntityId)
        .removeListener(_onCanvasStateChanged);
    super.dispose();
  }

  void _startCursorTimer() {
    _cursorTimer?.cancel();
    _cursorVisible = true;
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
      }
    });
  }

  void _stopCursorTimer() {
    _cursorTimer?.cancel();
    if (mounted) {
      setState(() {
        _cursorVisible = false;
      });
    }
  }

  void _onCanvasStateChanged() {
    if (_focusNode.hasFocus) return;
    final canvasState = widget.renderingSystem
        .get<EditorCanvasComponent>(widget.editorEntityId);
    if (canvasState == null) return;
    if (_controller.text != canvasState.currentExpression) {
      _isProgrammaticUpdate = true;
      _controller.text = canvasState.currentExpression;
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _startCursorTimer();
    } else {
      _stopCursorTimer();
      _onCanvasStateChanged();
    }
    if (mounted) setState(() {});
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
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Stack(
                children: [
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      focusNode: _focusNode,
                      controller: _controller,
                      onChanged: _onTextChanged,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _FormulaSyntaxPainter(
                      text: _controller.text,
                      textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          color: Colors.white),
                      selection: _controller.selection,
                      hasFocus: _focusNode.hasFocus,
                      cursorVisible: _cursorVisible,
                    ),
                    child: const SizedBox(height: 24),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Optimized Custom Painter with Caching ---

class _FormulaSyntaxPainter extends CustomPainter {
  final String text;
  final TextStyle textStyle;
  final TextSelection selection;
  final bool hasFocus;
  final bool cursorVisible;

  late final List<
      ({
        TextPainter painter,
        Rect? backgroundRect,
        Offset textOffset,
        TokenType type
      })> _laidOutTokens;
  late double _cursorX;

  _FormulaSyntaxPainter({
    required this.text,
    required this.textStyle,
    required this.selection,
    required this.hasFocus,
    required this.cursorVisible,
  }) {
    _layoutTokens();
  }

  void _layoutTokens() {
    _laidOutTokens = [];
    final tokens = _tokenize(text);
    double dx = 0.0;
    _cursorX = 0.0;

    // CRITICAL FIX: Clamp the selection offset to prevent RangeError.
    final validOffset = selection.baseOffset.clamp(0, text.length);

    final cursorPainter = TextPainter(
      text: TextSpan(text: text.substring(0, validOffset), style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    _cursorX = cursorPainter.width;

    for (final token in tokens) {
      final style = _getStyleForToken(token.type);
      final painter = TextPainter(
        text: TextSpan(text: token.text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      Rect? backgroundRect;
      Offset textOffset;
      double tokenWidth = painter.width;

      if (token.type == TokenType.variable) {
        backgroundRect = Rect.fromLTWH(dx, 0, painter.width + 8, 24);
        textOffset = Offset(dx + 4, (24 - painter.height) / 2);
        tokenWidth += 8;
      } else if (token.type == TokenType.unknown) {
        backgroundRect = Rect.fromLTWH(dx, 2, painter.width + 8, 20);
        textOffset = Offset(dx + 4, (24 - painter.height) / 2);
        tokenWidth += 8;
      } else {
        textOffset = Offset(dx, (24 - painter.height) / 2);
      }

      _laidOutTokens.add((
        painter: painter,
        backgroundRect: backgroundRect,
        textOffset: textOffset,
        type: token.type
      ));
      dx += tokenWidth;
    }
  }

  List<Token> _tokenize(String text) {
    final tokens = <Token>[];
    final regex = RegExp(
        r'([a-zA-Z\u0600-\u06FF_][a-zA-Z0-9\u0600-\u06FF_\s]*)|(\d+\.?\d*)|([+\-*/()])|(\s+)|(.)');

    final matches = regex.allMatches(text);
    for (final match in matches) {
      String tokenText = match.group(0)!;
      TokenType type;
      if (match.group(1) != null)
        type = TokenType.variable;
      else if (match.group(2) != null)
        type = TokenType.number;
      else if (match.group(3) != null)
        type = TokenType.operator;
      else if (match.group(4) != null)
        type = TokenType.whitespace;
      else
        type = TokenType.unknown;

      tokens.add(Token(tokenText, type));
    }
    return tokens;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final tokenData in _laidOutTokens) {
      if (tokenData.backgroundRect != null) {
        final bgPaint = Paint()..color = _getBgColorForToken(tokenData.type);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                tokenData.backgroundRect!, const Radius.circular(4)),
            bgPaint);
      }
      tokenData.painter.paint(canvas, tokenData.textOffset);
    }

    if (hasFocus && cursorVisible) {
      final cursorPaint = Paint()
        ..color = Colors.amber
        ..strokeWidth = 2;
      canvas.drawLine(
          Offset(_cursorX, 0), Offset(_cursorX, size.height), cursorPaint);
    }
  }

  TextStyle _getStyleForToken(TokenType type) {
    switch (type) {
      case TokenType.variable:
        return textStyle.copyWith(
            color: Colors.white, fontWeight: FontWeight.bold);
      case TokenType.number:
        return textStyle.copyWith(color: const Color(0xFFf97316));
      case TokenType.operator:
        return textStyle.copyWith(color: const Color(0xFF9ca3af));
      case TokenType.unknown:
        return textStyle.copyWith(color: Colors.white);
      case TokenType.whitespace:
        return textStyle;
    }
  }

  Color _getBgColorForToken(TokenType type) {
    switch (type) {
      case TokenType.variable:
        return const Color(0xFF3b82f6);
      case TokenType.unknown:
        return Colors.red.withOpacity(0.5);
      default:
        return Colors.transparent;
    }
  }

  @override
  bool shouldRepaint(covariant _FormulaSyntaxPainter oldDelegate) {
    return text != oldDelegate.text ||
        selection != oldDelegate.selection ||
        hasFocus != oldDelegate.hasFocus ||
        cursorVisible != oldDelegate.cursorVisible;
  }
}
