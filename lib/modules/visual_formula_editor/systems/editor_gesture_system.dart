// FILE: lib/modules/visual_formula_editor/systems/editor_gesture_system.dart
// (English comments for code clarity)
// REFACTORED v1.2: A complete overhaul for a more intuitive gesture system.
// - Scale is now ONLY for pan/zoom.
// - A simple Pan (tap and drag) is now used for node dragging and connecting.

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
  EntityId? _activeNodeId;
  String? _activePortId;
  double _lastFocalX = 0.0;
  double _lastFocalY = 0.0;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    // Pan and Zoom gestures (typically two-finger)
    listen<CanvasScaleStartEvent>(_onScaleStart);
    listen<CanvasScaleUpdateEvent>(_onScaleUpdate);
    listen<CanvasScaleEndEvent>(_onScaleEnd);

    // Node Dragging and Connection gestures (one-finger drag)
    listen<CanvasPanStartEvent>(_onPanStart);
    listen<CanvasPanUpdateEvent>(_onPanUpdate);
    listen<CanvasPanEndEvent>(_onPanEnd);
  }

  Entity? _getCanvasEntity() {
    return world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
  }

  // --- Pan and Zoom Logic (Scale Gestures) ---

  void _onScaleStart(CanvasScaleStartEvent event) {
    _mode = InteractionMode.panning;
    _lastFocalX = event.focalX;
    _lastFocalY = event.focalY;
  }

  void _onScaleUpdate(CanvasScaleUpdateEvent event) {
    if (_mode != InteractionMode.panning) return;

    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    if (event.scale != 1.0) {
      // Zooming
      final newZoom = (canvasState.zoom * event.scale).clamp(0.2, 3.0);
      final panX = event.focalX -
          (event.focalX - canvasState.panX) * (newZoom / canvasState.zoom);
      final panY = event.focalY -
          (event.focalY - canvasState.panY) * (newZoom / canvasState.zoom);
      canvasEntity
          .add(canvasState.copyWith(zoom: newZoom, panX: panX, panY: panY));
    } else {
      // Panning
      canvasEntity.add(canvasState.copyWith(
        panX: canvasState.panX + (event.focalX - _lastFocalX),
        panY: canvasState.panY + (event.focalY - _lastFocalY),
      ));
    }

    _lastFocalX = event.focalX;
    _lastFocalY = event.focalY;
  }

  void _onScaleEnd(CanvasScaleEndEvent event) {
    if (_mode == InteractionMode.panning) {
      _mode = InteractionMode.none;
    }
  }

  // --- Node Dragging & Connection Logic (Pan Gestures) ---

  void _onPanStart(CanvasPanStartEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    if (canvasState.contextMenuNodeId != null) {
      world.eventBus.fire(HideContextMenuEvent());
    }

    final canvasX = (event.localX - canvasState.panX) / canvasState.zoom;
    final canvasY = (event.localY - canvasState.panY) / canvasState.zoom;

    final nodeHit = getNodeAt(world, canvasX, canvasY);

    if (nodeHit != null) {
      final portHit = getPortAt(nodeHit, canvasX, canvasY);
      if (portHit != null &&
          nodeHit
              .get<NodeComponent>()!
              .outputs
              .any((p) => p.id == portHit.port.id)) {
        // Started on an output port -> Create Connection
        _mode = InteractionMode.creatingConnection;
        _activeNodeId = nodeHit.id;
        _activePortId = portHit.port.id;
        canvasEntity.add(canvasState.copyWith(
          connectionStartNodeId: _activeNodeId,
          connectionStartPortId: _activePortId,
          connectionDraftX: portHit.x,
          connectionDraftY: portHit.y,
        ));
      } else {
        // Started on a node body -> Drag Node
        _mode = InteractionMode.draggingNode;
        _activeNodeId = nodeHit.id;
      }
    }
  }

  void _onPanUpdate(CanvasPanUpdateEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    switch (_mode) {
      case InteractionMode.draggingNode:
        final draggedEntity = world.entities[_activeNodeId!];
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
        final canvasX = (event.localX - canvasState.panX) / canvasState.zoom;
        final canvasY = (event.localY - canvasState.panY) / canvasState.zoom;
        canvasEntity.add(canvasState.copyWith(
          connectionDraftX: canvasX,
          connectionDraftY: canvasY,
        ));
        break;
      default:
        break;
    }
  }

  void _onPanEnd(CanvasPanEndEvent event) {
    if (_mode == InteractionMode.creatingConnection) {
      final canvasEntity = _getCanvasEntity()!;
      final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
      final endX = (event.localX - canvasState.panX) / canvasState.zoom;
      final endY = (event.localY - canvasState.panY) / canvasState.zoom;
      final targetNode = getNodeAt(world, endX, endY);
      final portHit =
          (targetNode != null) ? getPortAt(targetNode, endX, endY) : null;

      world.eventBus.fire(FinalizeConnectionEvent(
        fromNodeId: _activeNodeId!,
        fromPortId: _activePortId!,
        targetNode: targetNode,
        targetPort: portHit?.port,
      ));
    }

    _mode = InteractionMode.none;
    _activeNodeId = null;
    _activePortId = null;

    final canvasEntity = _getCanvasEntity();
    if (canvasEntity != null) {
      final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
      canvasEntity.add(canvasState.copyWith(
        clearConnectionStartNodeId: true,
        clearConnectionStartPortId: true,
        clearConnectionDraftX: true,
        clearConnectionDraftY: true,
      ));
    }
  }

  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
