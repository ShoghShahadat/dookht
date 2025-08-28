// FILE: lib/modules/visual_formula_editor/editor_events.dart
// (English comments for code clarity)
// MODIFIED v1.7: Added events for selection and settings management.

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
  final double deltaX;
  final double deltaY;
  CanvasScaleUpdateEvent(
      {required this.focalX,
      required this.focalY,
      required this.scale,
      required this.deltaX,
      required this.deltaY});
}

class CanvasScaleEndEvent {}

class CanvasTapUpEvent {
  final double localX;
  final double localY;
  final EntityId? tappedEntityId; // Can be a node or connection
  CanvasTapUpEvent(
      {required this.localX, required this.localY, this.tappedEntityId});
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

class RecalculateGraphEvent {}

// FIX: New events for managing selection and settings
class SelectEntityEvent {
  final EntityId? entityId;
  SelectEntityEvent(this.entityId);
}

class OpenNodeSettingsEvent {
  final EntityId nodeId;
  OpenNodeSettingsEvent(this.nodeId);
}

class CloseNodeSettingsEvent {}

class UpdateNodeDataEvent {
  final EntityId nodeId;
  final Map<String, dynamic> newData;
  UpdateNodeDataEvent({required this.nodeId, required this.newData});
}
