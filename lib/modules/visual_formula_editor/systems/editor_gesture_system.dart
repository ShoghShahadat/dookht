// FILE: lib/modules/visual_formula_editor/systems/editor_gesture_system.dart
// (English comments for code clarity)
// REFACTORED v2.0: Logic is streamlined for clarity and robustness.
// Dragging is now explicitly managed via the draggedEntityId in the canvas state.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_connection_management_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

enum InteractionMode { none, draggingNode, panning, creatingConnection }

/// Handles all gesture-based interactions within the visual formula editor.
class EditorGestureSystem extends System {
  InteractionMode _mode = InteractionMode.none;
  double _lastFocalX = 0.0;
  double _lastFocalY = 0.0;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CanvasScaleStartEvent>(_onScaleStart);
    listen<CanvasScaleUpdateEvent>(_onScaleUpdate);
    listen<CanvasScaleEndEvent>(_onScaleEnd);
  }

  Entity? _getCanvasEntity() {
    return world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
  }

  void _onScaleStart(CanvasScaleStartEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    // Always hide context menu on new interaction
    if (canvasState.contextMenuNodeId != null) {
      world.eventBus.fire(HideContextMenuEvent());
    }

    final canvasX = (event.focalX - canvasState.panX) / canvasState.zoom;
    final canvasY = (event.focalY - canvasState.panY) / canvasState.zoom;

    final nodeHit = getNodeAt(world, canvasX, canvasY);

    if (nodeHit != null) {
      final portHit = getPortAt(nodeHit, canvasX, canvasY);
      final isOutputPort = nodeHit
          .get<NodeComponent>()!
          .outputs
          .any((p) => p.id == portHit?.port.id);

      if (portHit != null && isOutputPort) {
        // Start creating a connection if dragging from an output port
        _mode = InteractionMode.creatingConnection;
        canvasEntity.add(canvasState.copyWith(
          connectionStartNodeId: nodeHit.id,
          connectionStartPortId: portHit.port.id,
          connectionDraftX: portHit.x,
          connectionDraftY: portHit.y,
        ));
      } else {
        // Start dragging the node itself
        _mode = InteractionMode.draggingNode;
        canvasEntity.add(canvasState.copyWith(draggedEntityId: nodeHit.id));
      }
    } else {
      // If no node is hit, start panning the canvas
      _mode = InteractionMode.panning;
    }
    _lastFocalX = event.focalX;
    _lastFocalY = event.focalY;
  }

  void _onScaleUpdate(CanvasScaleUpdateEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    switch (_mode) {
      case InteractionMode.draggingNode:
        final draggedId = canvasState.draggedEntityId;
        if (draggedId == null) break;
        final draggedEntity = world.entities[draggedId];
        if (draggedEntity == null) break;

        final nodeComp = draggedEntity.get<NodeComponent>()!;
        draggedEntity.add(nodeComp.copyWith(
          position: PositionComponent(
            x: nodeComp.position.x + (event.deltaX / canvasState.zoom),
            y: nodeComp.position.y + (event.deltaY / canvasState.zoom),
            width: nodeComp.position.width,
            height: nodeComp.position.height,
          ),
        ));
        break;

      case InteractionMode.creatingConnection:
        final draftX = (event.focalX - canvasState.panX) / canvasState.zoom;
        final draftY = (event.focalY - canvasState.panY) / canvasState.zoom;
        canvasEntity.add(canvasState.copyWith(
          connectionDraftX: draftX,
          connectionDraftY: draftY,
        ));
        break;

      case InteractionMode.panning:
        if (event.scale != 1.0) {
          final newZoom = (canvasState.zoom * event.scale).clamp(0.2, 3.0);
          final panX = event.focalX -
              (event.focalX - canvasState.panX) * (newZoom / canvasState.zoom);
          final panY = event.focalY -
              (event.focalY - canvasState.panY) * (newZoom / canvasState.zoom);
          canvasEntity
              .add(canvasState.copyWith(zoom: newZoom, panX: panX, panY: panY));
        } else {
          canvasEntity.add(canvasState.copyWith(
            panX: canvasState.panX + (event.focalX - _lastFocalX),
            panY: canvasState.panY + (event.focalY - _lastFocalY),
          ));
        }
        break;

      case InteractionMode.none:
        break;
    }
    _lastFocalX = event.focalX;
    _lastFocalY = event.focalY;
  }

  void _onScaleEnd(CanvasScaleEndEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    if (_mode == InteractionMode.creatingConnection) {
      final endX = canvasState.connectionDraftX!;
      final endY = canvasState.connectionDraftY!;
      final targetNode = getNodeAt(world, endX, endY);
      final portHit =
          (targetNode != null) ? getPortAt(targetNode, endX, endY) : null;

      world.eventBus.fire(FinalizeConnectionEvent(
        fromNodeId: canvasState.connectionStartNodeId!,
        fromPortId: canvasState.connectionStartPortId!,
        targetNode: targetNode,
        targetPort: portHit?.port,
      ));
    }

    _mode = InteractionMode.none;
    canvasEntity.add(canvasState.copyWith(
      clearDraggedEntityId: true,
      clearConnectionStartNodeId: true,
      clearConnectionStartPortId: true,
      clearConnectionDraftX: true,
      clearConnectionDraftY: true,
    ));
  }

  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
