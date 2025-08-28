// FILE: lib/modules/visual_formula_editor/editor_events.dart
// (English comments for code clarity)
// MODIFIED v3.1: Added new gesture events and simplified others.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';

// --- Raw Gesture Events from UI to Logic ---

class CanvasScaleStartEvent {
  final double focalX;
  final double focalY;
  CanvasScaleStartEvent({required this.focalX, required this.focalY});
}

class CanvasScaleUpdateEvent {
  final double focalX;
  final double focalY;
  final double scale;
  CanvasScaleUpdateEvent(
      {required this.focalX, required this.focalY, required this.scale});
}

class CanvasScaleEndEvent {}

class CanvasTapUpEvent {
  final double localX;
  final double localY;
  CanvasTapUpEvent({required this.localX, required this.localY});
}

class CanvasLongPressStartEvent {
  final double localX;
  final double localY;
  CanvasLongPressStartEvent({required this.localX, required this.localY});
}

// --- Action Events from UI/Systems to Systems ---

class AddNodeEvent {
  final NodeType type;
  AddNodeEvent(this.type);
}

class UpdatePreviewInputEvent {
  final String inputId;
  final double? value;
  UpdatePreviewInputEvent({required this.inputId, this.value});
}

class HideContextMenuEvent {}

class DeleteNodeEvent {
  final EntityId nodeId;
  DeleteNodeEvent(this.nodeId);
}

class DeleteConnectionEvent {
  final EntityId connectionId;
  DeleteConnectionEvent(this.connectionId);
}
