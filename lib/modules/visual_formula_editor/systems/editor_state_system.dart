// FILE: lib/modules/visual_formula_editor/systems/editor_state_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: Updated _onUpdateNodeData to handle label changes.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

/// Manages non-gesture-related state changes for the editor.
class EditorStateSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdatePreviewInputEvent>(_onUpdatePreviewInput);
    listen<SelectEntityEvent>(_onSelectEntity);
    listen<OpenNodeSettingsEvent>(_onOpenNodeSettings);
    listen<CloseNodeSettingsEvent>(_onCloseNodeSettings);
    listen<UpdateNodeDataEvent>(_onUpdateNodeData);
  }

  Entity? _getCanvasEntity() {
    return world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
  }

  void _onUpdatePreviewInput(UpdatePreviewInputEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;

    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    final newValues = Map<String, double>.from(canvasState.previewInputValues);
    if (event.value != null) {
      newValues[event.inputId] = event.value!;
    } else {
      newValues.remove(event.inputId);
    }

    canvasEntity.add(canvasState.copyWith(previewInputValues: newValues));
    world.eventBus.fire(RecalculateGraphEvent());
  }

  void _onSelectEntity(SelectEntityEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(canvasState.copyWith(
      selectedEntityId: event.entityId,
      clearSelectedEntityId: event.entityId == null,
    ));
  }

  void _onOpenNodeSettings(OpenNodeSettingsEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(canvasState.copyWith(settingsNodeId: event.nodeId));
  }

  void _onCloseNodeSettings(CloseNodeSettingsEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(canvasState.copyWith(clearSettingsNodeId: true));
  }

  void _onUpdateNodeData(UpdateNodeDataEvent event) {
    final nodeEntity = world.entities[event.nodeId];
    if (nodeEntity == null) return;
    final nodeComp = nodeEntity.get<NodeComponent>();
    if (nodeComp == null) return;

    final newCombinedData = (event.newData != null)
        ? (Map<String, dynamic>.from(nodeComp.data)..addAll(event.newData!))
        : nodeComp.data;

    // Prioritize the new label if provided, otherwise check for operator change.
    String newLabel = event.newLabel ?? nodeComp.label;
    if (event.newData?.containsKey('operator') ?? false) {
      newLabel = event.newData!['operator'];
    }

    nodeEntity.add(nodeComp.copyWith(data: newCombinedData, label: newLabel));
    world.eventBus.fire(RecalculateGraphEvent());
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven
  @override
  void update(Entity entity, double dt) {}
}
