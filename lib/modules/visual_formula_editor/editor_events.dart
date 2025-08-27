// FILE: lib/modules/visual_formula_editor/editor_events.dart
// (English comments for code clarity)

import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';

/// Event fired when the user presses down on the canvas.
class CanvasPointerDownEvent {
  final double localX;
  final double localY;

  CanvasPointerDownEvent({required this.localX, required this.localY});
}

/// Event fired when the user drags their pointer across the canvas.
class CanvasPointerMoveEvent {
  final double deltaX;
  final double deltaY;

  CanvasPointerMoveEvent({required this.deltaX, required this.deltaY});
}

/// Event fired when the user lifts their pointer from the canvas.
class CanvasPointerUpEvent {}

/// Event fired to add a new node to the canvas.
class AddNodeEvent {
  final NodeType type;

  AddNodeEvent(this.type);
}

/// Event fired to update an input value in the preview panel.
class UpdatePreviewInputEvent {
  final String inputId;
  final double? value;

  UpdatePreviewInputEvent({required this.inputId, this.value});
}
