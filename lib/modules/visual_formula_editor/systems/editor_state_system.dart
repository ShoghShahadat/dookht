// FILE: lib/modules/visual_formula_editor/systems/editor_state_system.dart
// (English comments for code clarity)
// This new system is dedicated to managing non-gesture state changes, like preview inputs.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

/// Manages non-gesture-related state changes for the editor, such as updating preview values.
class EditorStateSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdatePreviewInputEvent>(_onUpdatePreviewInput);
  }

  void _onUpdatePreviewInput(UpdatePreviewInputEvent event) {
    final canvasEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
    if (canvasEntity == null) return;

    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    final newValues = Map<String, double>.from(canvasState.previewInputValues);
    if (event.value != null) {
      newValues[event.inputId] = event.value!;
    } else {
      newValues.remove(event.inputId);
    }

    canvasEntity.add(canvasState.copyWith(previewInputValues: newValues));

    // Crucially, fire the event to trigger a recalculation of the graph.
    world.eventBus.fire(RecalculateGraphEvent());
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven
  @override
  void update(Entity entity, double dt) {}
}
