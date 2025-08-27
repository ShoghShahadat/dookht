// FILE: lib/modules/visual_formula_editor/editor_events.dart
// (English comments for code clarity)

import 'package:nexus/nexus.dart';
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
class CanvasPointerUpEvent {
  final double localX;
  final double localY;

  CanvasPointerUpEvent({required this.localX, required this.localY});
}

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

/// Event fired to show the context menu for a node.
class ShowNodeContextMenuEvent {
  final EntityId nodeId;
  final double x;
  final double y;

  ShowNodeContextMenuEvent(
      {required this.nodeId, required this.x, required this.y});
}

/// Event fired to hide the context menu.
class HideContextMenuEvent {}

/// Event fired to delete a node.
class DeleteNodeEvent {
  final EntityId nodeId;

  DeleteNodeEvent(this.nodeId);
}

/// Event fired to delete a connection.
class DeleteConnectionEvent {
  final EntityId connectionId;

  DeleteConnectionEvent(this.connectionId);
}

/// Event fired when the user pans the canvas.
class CanvasPanEvent {
  final double deltaX;
  final double deltaY;

  CanvasPanEvent({required this.deltaX, required this.deltaY});
}

/// Event fired when the user zooms the canvas.
class CanvasZoomEvent {
  final double zoomDelta;
  final double localX; // Anchor point for zooming
  final double localY;

  CanvasZoomEvent(
      {required this.zoomDelta, required this.localX, required this.localY});
}
