// FILE: lib/modules/visual_formula_editor/visual_editor_system.dart
// (English comments for code clarity)

import 'dart:math';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

const double portRadius = 10.0; // Increased for easier tapping

/// Handles all interaction logic within the visual formula editor.
class VisualEditorSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CanvasPointerDownEvent>(_onPointerDown);
    listen<CanvasPointerMoveEvent>(_onPointerMove);
    listen<CanvasPointerUpEvent>(_onPointerUp);
    listen<AddNodeEvent>(_onAddNode);
    listen<UpdatePreviewInputEvent>(_onUpdatePreviewInput);
    listen<ShowNodeContextMenuEvent>(_onShowContextMenu);
    listen<HideContextMenuEvent>(_onHideContextMenu);
    listen<DeleteNodeEvent>(_onDeleteNode);
    listen<DeleteConnectionEvent>(_onDeleteConnection);
    listen<CanvasPanEvent>(_onPan);
    listen<CanvasZoomEvent>(_onZoom);
  }

  Entity? _getCanvasEntity() {
    return world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
  }

  // --- Event Handlers ---

  void _onPan(CanvasPanEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(EditorCanvasComponent(
      panX: canvasState.panX + event.deltaX,
      panY: canvasState.panY + event.deltaY,
      zoom: canvasState.zoom,
      previewInputValues: canvasState.previewInputValues,
    ));
  }

  void _onZoom(CanvasZoomEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    final newZoom = (canvasState.zoom * event.zoomDelta).clamp(0.2, 3.0);

    // Adjust pan to zoom towards the pointer location
    final panX = event.localX -
        (event.localX - canvasState.panX) * (newZoom / canvasState.zoom);
    final panY = event.localY -
        (event.localY - canvasState.panY) * (newZoom / canvasState.zoom);

    canvasEntity.add(EditorCanvasComponent(
      panX: panX,
      panY: panY,
      zoom: newZoom,
      previewInputValues: canvasState.previewInputValues,
    ));
  }

  void _onDeleteNode(DeleteNodeEvent event) {
    // Delete all connections attached to this node
    final connections = world.entities.values.where((e) {
      final c = e.get<ConnectionComponent>();
      return c != null &&
          (c.fromNodeId == event.nodeId || c.toNodeId == event.nodeId);
    }).toList();

    for (final conn in connections) {
      world.removeEntity(conn.id);
    }
    // Delete the node itself
    world.removeEntity(event.nodeId);
  }

  void _onDeleteConnection(DeleteConnectionEvent event) {
    world.removeEntity(event.connectionId);
  }

  void _onShowContextMenu(ShowNodeContextMenuEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(EditorCanvasComponent(
      contextMenuNodeId: event.nodeId,
      contextMenuX: event.x,
      contextMenuY: event.y,
      panX: canvasState.panX,
      panY: canvasState.panY,
      zoom: canvasState.zoom,
      previewInputValues: canvasState.previewInputValues,
    ));
  }

  void _onHideContextMenu(HideContextMenuEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(EditorCanvasComponent(
      contextMenuNodeId: null,
      contextMenuX: null,
      contextMenuY: null,
      panX: canvasState.panX,
      panY: canvasState.panY,
      zoom: canvasState.zoom,
      previewInputValues: canvasState.previewInputValues,
    ));
  }

  // ... other event handlers are mostly the same but need to preserve state ...
  // (Full code for other handlers is provided for completeness)

  void _onAddNode(AddNodeEvent event) {
    final canvasEntity = _getCanvasEntity();
    final canvasState = canvasEntity?.get<EditorCanvasComponent>();
    // Add new nodes in the center of the current view
    final x =
        (canvasState != null) ? -canvasState.panX / canvasState.zoom : 100;
    final y =
        (canvasState != null) ? -canvasState.panY / canvasState.zoom : 100;

    final newNode = _createNodeFromType(event.type, x.toDouble(), y.toDouble());
    world.addEntity(newNode);
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

    canvasEntity.add(EditorCanvasComponent(
      previewInputValues: newValues,
      panX: canvasState.panX,
      panY: canvasState.panY,
      zoom: canvasState.zoom,
    ));
  }

  void _onPointerDown(CanvasPointerDownEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    // Hide context menu on any new press
    if (canvasState.contextMenuNodeId != null) {
      world.eventBus.fire(HideContextMenuEvent());
    }

    final nodes =
        world.entities.values.where((e) => e.has<NodeComponent>()).toList();

    for (final node in nodes.reversed) {
      final nodeComp = node.get<NodeComponent>()!;
      final pos = nodeComp.position;

      final portHit = _getPortAt(node, event.localX, event.localY);
      if (portHit != null) {
        final isOutput = nodeComp.outputs.any((p) => p.id == portHit.port.id);
        if (isOutput) {
          canvasEntity.add(EditorCanvasComponent(
            draggedEntityId: null,
            connectionStartNodeId: node.id,
            connectionStartPortId: portHit.port.id,
            connectionDraftX: portHit.x,
            connectionDraftY: portHit.y,
            panX: canvasState.panX,
            panY: canvasState.panY,
            zoom: canvasState.zoom,
            previewInputValues: canvasState.previewInputValues,
          ));
        }
        return;
      }

      if (event.localX >= pos.x &&
          event.localX <= pos.x + pos.width &&
          event.localY >= pos.y &&
          event.localY <= pos.y + pos.height) {
        canvasEntity.add(EditorCanvasComponent(
          draggedEntityId: node.id,
          panX: canvasState.panX,
          panY: canvasState.panY,
          zoom: canvasState.zoom,
          previewInputValues: canvasState.previewInputValues,
        ));
        return;
      }
    }
  }

  void _onPointerMove(CanvasPointerMoveEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    if (canvasState.draggedEntityId != null) {
      _handleNodeDrag(canvasState, event);
    } else if (canvasState.connectionStartNodeId != null) {
      _handleConnectionDraft(canvasState, event);
    }
  }

  void _onPointerUp(CanvasPointerUpEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    // Check for connection tap to delete
    if (canvasState.draggedEntityId == null &&
        canvasState.connectionStartNodeId == null) {
      final connectionToDelete = _getConnectionAt(event.localX, event.localY);
      if (connectionToDelete != null) {
        world.eventBus.fire(DeleteConnectionEvent(connectionToDelete.id));
        return;
      }
    }

    if (canvasState.connectionStartNodeId != null) {
      final nodes = world.entities.values.where((e) => e.has<NodeComponent>());
      for (final node in nodes) {
        final portHit = _getPortAt(
            node, canvasState.connectionDraftX!, canvasState.connectionDraftY!);
        if (portHit != null) {
          final isInput = node
              .get<NodeComponent>()!
              .inputs
              .any((p) => p.id == portHit.port.id);
          if (isInput) {
            final newConnection = Entity()
              ..add(ConnectionComponent(
                fromNodeId: canvasState.connectionStartNodeId!,
                fromPortId: canvasState.connectionStartPortId!,
                toNodeId: node.id,
                toPortId: portHit.port.id,
              ))
              ..add(LifecyclePolicyComponent(isPersistent: true))
              ..add(TagsComponent({'connection_component'}));
            world.addEntity(newConnection);
            break;
          }
        }
      }
    }

    canvasEntity.add(EditorCanvasComponent(
      panX: canvasState.panX,
      panY: canvasState.panY,
      zoom: canvasState.zoom,
      previewInputValues: canvasState.previewInputValues,
    ));
  }

  void _handleNodeDrag(
      EditorCanvasComponent state, CanvasPointerMoveEvent event) {
    final draggedEntity = world.entities[state.draggedEntityId!];
    if (draggedEntity == null) return;
    final nodeComp = draggedEntity.get<NodeComponent>()!;
    final pos = nodeComp.position;
    final canvasState = _getCanvasEntity()!.get<EditorCanvasComponent>()!;

    final newPosition = PositionComponent(
      x: pos.x + (event.deltaX / canvasState.zoom),
      y: pos.y + (event.deltaY / canvasState.zoom),
      width: pos.width,
      height: pos.height,
    );

    draggedEntity.add(NodeComponent(
      label: nodeComp.label,
      type: nodeComp.type,
      position: newPosition,
      data: nodeComp.data,
      inputs: nodeComp.inputs,
      outputs: nodeComp.outputs,
    ));
  }

  void _handleConnectionDraft(
      EditorCanvasComponent state, CanvasPointerMoveEvent event) {
    final canvasEntity = _getCanvasEntity()!;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(EditorCanvasComponent(
        connectionStartNodeId: state.connectionStartNodeId,
        connectionStartPortId: state.connectionStartPortId,
        connectionDraftX:
            state.connectionDraftX! + (event.deltaX / canvasState.zoom),
        connectionDraftY:
            state.connectionDraftY! + (event.deltaY / canvasState.zoom),
        panX: state.panX,
        panY: state.panY,
        zoom: state.zoom,
        previewInputValues: state.previewInputValues));
  }

  ({NodePort port, double x, double y})? _getPortAt(
      Entity node, double hx, double hy) {
    final nodeComp = node.get<NodeComponent>()!;
    final pos = nodeComp.position;

    for (var i = 0; i < nodeComp.outputs.length; i++) {
      final port = nodeComp.outputs[i];
      final px = pos.x + pos.width;
      final py = pos.y + (pos.height / (nodeComp.outputs.length + 1)) * (i + 1);
      if (sqrt(pow(hx - px, 2) + pow(hy - py, 2)) < portRadius) {
        return (port: port, x: px, y: py);
      }
    }

    for (var i = 0; i < nodeComp.inputs.length; i++) {
      final port = nodeComp.inputs[i];
      final px = pos.x;
      final py = pos.y + (pos.height / (nodeComp.inputs.length + 1)) * (i + 1);
      if (sqrt(pow(hx - px, 2) + pow(hy - py, 2)) < portRadius) {
        return (port: port, x: px, y: py);
      }
    }
    return null;
  }

  Entity? _getConnectionAt(double hx, double hy) {
    // A simple hit test for connections (checks midpoint)
    final connections =
        world.entities.values.where((e) => e.has<ConnectionComponent>());
    for (final connEntity in connections) {
      final conn = connEntity.get<ConnectionComponent>()!;
      final fromNode = world.entities[conn.fromNodeId]?.get<NodeComponent>();
      final toNode = world.entities[conn.toNodeId]?.get<NodeComponent>();
      if (fromNode == null || toNode == null) continue;

      // This is a simplified hit test. A real implementation would check distance to the curve.
      final start = _getPortPosition(fromNode, conn.fromPortId, true);
      final end = _getPortPosition(toNode, conn.toPortId, false);
      if (start == null || end == null) continue;

      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;

      if (sqrt(pow(hx - midX, 2) + pow(hy - midY, 2)) < 10.0) {
        return connEntity;
      }
    }
    return null;
  }

  Offset? _getPortPosition(NodeComponent node, String portId, bool isOutput) {
    final pos = node.position;
    final ports = isOutput ? node.outputs : node.inputs;
    final index = ports.indexWhere((p) => p.id == portId);
    if (index == -1) return null;

    final x = isOutput ? pos.x + pos.width : pos.x;
    final y = pos.y + (pos.height / (ports.length + 1)) * (index + 1);
    return Offset(x, y);
  }

  Entity _createNodeFromType(NodeType type, double x, double y) {
    final random = Random();
    final position = PositionComponent(x: x, y: y);
    NodeComponent nodeComp;

    switch (type) {
      case NodeType.input:
        nodeComp = NodeComponent(
            label: 'ورودی جدید',
            type: type,
            position: position
              ..width = 150
              ..height = 80,
            outputs: [NodePort(id: 'value', label: 'مقدار')],
            data: {'inputId': 'input_${random.nextInt(1000)}'});
        break;
      case NodeType.constant:
        nodeComp = NodeComponent(
            label: 'مقدار ثابت',
            type: type,
            position: position
              ..width = 150
              ..height = 80,
            outputs: [NodePort(id: 'value', label: 'مقدار')],
            data: {'value': 4.0});
        break;
      case NodeType.operator:
        nodeComp = NodeComponent(
            label: '+',
            type: type,
            position: position
              ..width = 80
              ..height = 100,
            data: {
              'operator': '+'
            },
            inputs: [
              NodePort(id: 'a', label: 'A'),
              NodePort(id: 'b', label: 'B')
            ],
            outputs: [
              NodePort(id: 'result', label: 'نتیجه')
            ]);
        break;
      case NodeType.output:
        nodeComp = NodeComponent(
            label: 'خروجی جدید',
            type: type,
            position: position
              ..width = 150
              ..height = 80,
            inputs: [NodePort(id: 'value', label: 'مقدار')]);
        break;
      case NodeType.condition:
        nodeComp = NodeComponent(
            label: 'اگر',
            type: type,
            position: position
              ..width = 150
              ..height = 120,
            inputs: [
              NodePort(id: 'condition', label: 'شرط'),
              NodePort(id: 'if_true', label: 'در صورت صحت'),
              NodePort(id: 'if_false', label: 'در صورت غلط')
            ],
            outputs: [
              NodePort(id: 'result', label: 'نتیجه')
            ]);
        break;
    }

    return Entity()
      ..add(TagsComponent({'node_component'}))
      ..add(nodeComp)
      ..add(LifecyclePolicyComponent(isPersistent: true));
  }

  @override
  bool matches(Entity entity) => false;
  @override
  void update(Entity entity, double dt) {}
}
