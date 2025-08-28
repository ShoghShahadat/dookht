// FILE: lib/modules/visual_formula_editor/visual_editor_system.dart
// (English comments for code clarity)
// FIX v4.2: Replaced direct instantiation with copyWith and fixed type casting.

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

const double portRadius = 10.0;

enum InteractionMode { none, draggingNode, panning, creatingConnection }

/// Handles all interaction logic within the visual formula editor.
class VisualEditorSystem extends System {
  InteractionMode _mode = InteractionMode.none;
  EntityId? _activeNodeId;
  String? _activePortId;
  double _lastFocalX = 0.0;
  double _lastFocalY = 0.0;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<CanvasScaleStartEvent>(_onScaleStart);
    listen<CanvasScaleUpdateEvent>(_onScaleUpdate);
    listen<CanvasScaleEndEvent>(_onScaleEnd);
    listen<CanvasTapUpEvent>(_onTapUp);
    listen<CanvasLongPressStartEvent>(_onLongPressStart);
    listen<AddNodeEvent>(_onAddNode);
    listen<UpdatePreviewInputEvent>(_onUpdatePreviewInput);
    listen<HideContextMenuEvent>(_onHideContextMenu);
    listen<DeleteNodeEvent>(_onDeleteNode);
    listen<DeleteConnectionEvent>(_onDeleteConnection);
  }

  Entity? _getCanvasEntity() {
    return world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
  }

  void _onScaleStart(CanvasScaleStartEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    if (canvasState.contextMenuNodeId != null) {
      _onHideContextMenu(HideContextMenuEvent());
    }

    final canvasX = (event.focalX - canvasState.panX) / canvasState.zoom;
    final canvasY = (event.focalY - canvasState.panY) / canvasState.zoom;

    final nodeHit = _getNodeAt(canvasX, canvasY);

    if (nodeHit != null) {
      final portHit = _getPortAt(nodeHit, canvasX, canvasY);
      if (portHit != null) {
        final isOutput = nodeHit
            .get<NodeComponent>()!
            .outputs
            .any((p) => p.id == portHit.port.id);
        if (isOutput) {
          _mode = InteractionMode.creatingConnection;
          _activeNodeId = nodeHit.id;
          _activePortId = portHit.port.id;
          canvasEntity.add(canvasState.copyWith(
            connectionStartNodeId: _activeNodeId,
            connectionStartPortId: _activePortId,
            connectionDraftX: portHit.x,
            connectionDraftY: portHit.y,
          ));
        }
      } else {
        _mode = InteractionMode.draggingNode;
        _activeNodeId = nodeHit.id;
      }
    } else {
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
        final draggedEntity = world.entities[_activeNodeId!];
        if (draggedEntity == null) break;
        final nodeComp = draggedEntity.get<NodeComponent>()!;
        draggedEntity.add(nodeComp.copyWith(
          position: PositionComponent(
            x: nodeComp.position.x +
                (event.focalX - _lastFocalX) / canvasState.zoom,
            y: nodeComp.position.y +
                (event.focalY - _lastFocalY) / canvasState.zoom,
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
    if (_mode == InteractionMode.creatingConnection) {
      _finalizeConnection();
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

  void _finalizeConnection() {
    final canvasEntity = _getCanvasEntity()!;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    final endX = canvasState.connectionDraftX!;
    final endY = canvasState.connectionDraftY!;

    final targetNode = _getNodeAt(endX, endY);
    if (targetNode != null && targetNode.id != _activeNodeId) {
      final portHit = _getPortAt(targetNode, endX, endY);
      if (portHit != null) {
        final isInput = targetNode
            .get<NodeComponent>()!
            .inputs
            .any((p) => p.id == portHit.port.id);
        if (isInput) {
          final newConnection = Entity()
            ..add(ConnectionComponent(
              fromNodeId: _activeNodeId!,
              fromPortId: _activePortId!,
              toNodeId: targetNode.id,
              toPortId: portHit.port.id,
            ))
            ..add(LifecyclePolicyComponent(isPersistent: true))
            ..add(TagsComponent({'connection_component'}));
          world.addEntity(newConnection);
        }
      }
    }
  }

  void _onTapUp(CanvasTapUpEvent event) {
    final connectionToDelete = _getConnectionAt(event.localX, event.localY);
    if (connectionToDelete != null) {
      world.eventBus.fire(DeleteConnectionEvent(connectionToDelete.id));
    }
  }

  void _onLongPressStart(CanvasLongPressStartEvent event) {
    final nodeHit = _getNodeAt(event.localX, event.localY);
    if (nodeHit != null) {
      final canvasEntity = _getCanvasEntity()!;
      final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
      canvasEntity.add(canvasState.copyWith(
        contextMenuNodeId: nodeHit.id,
        contextMenuX: nodeHit.get<NodeComponent>()!.position.x,
        contextMenuY: nodeHit.get<NodeComponent>()!.position.y,
      ));
    }
  }

  void _onHideContextMenu(HideContextMenuEvent event) {
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;
    canvasEntity.add(canvasState.copyWith(
      clearContextMenuNodeId: true,
      clearContextMenuX: true,
      clearContextMenuY: true,
    ));
  }

  void _onDeleteNode(DeleteNodeEvent event) {
    final connections = world.entities.values.where((e) {
      final c = e.get<ConnectionComponent>();
      return c != null &&
          (c.fromNodeId == event.nodeId || c.toNodeId == event.nodeId);
    }).toList();

    for (final conn in connections) {
      world.removeEntity(conn.id);
    }
    world.removeEntity(event.nodeId);
  }

  void _onDeleteConnection(DeleteConnectionEvent event) {
    world.removeEntity(event.connectionId);
  }

  void _onAddNode(AddNodeEvent event) {
    final canvasEntity = _getCanvasEntity();
    final canvasState = canvasEntity?.get<EditorCanvasComponent>();
    final x = (canvasState != null && canvasState.zoom != 0)
        ? -canvasState.panX / canvasState.zoom
        : 100;
    final y = (canvasState != null && canvasState.zoom != 0)
        ? -canvasState.panY / canvasState.zoom
        : 100;

    final newNode = _createNodeFromType(event.type, x, y);
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
    canvasEntity.add(canvasState.copyWith(previewInputValues: newValues));
  }

  Entity? _getNodeAt(double hx, double hy) {
    final nodes = world.entities.values.where((e) => e.has<NodeComponent>());
    for (final node in nodes.toList().reversed) {
      final nodeComp = node.get<NodeComponent>()!;
      final pos = nodeComp.position;
      if (hx >= pos.x &&
          hx <= pos.x + pos.width &&
          hy >= pos.y &&
          hy <= pos.y + pos.height) {
        return node;
      }
    }
    return null;
  }

  ({NodePort port, double x, double y})? _getPortAt(
      Entity node, double hx, double hy) {
    final nodeComp = node.get<NodeComponent>()!;
    final pos = nodeComp.position;

    for (var i = 0; i < nodeComp.outputs.length; i++) {
      final port = nodeComp.outputs[i];
      final px = pos.x + pos.width;
      final py = pos.y + (pos.height / (nodeComp.outputs.length + 1)) * (i + 1);
      if (sqrt(pow(hx - px, 2).toDouble() + pow(hy - py, 2).toDouble()) <
          portRadius) {
        return (port: port, x: px, y: py);
      }
    }

    for (var i = 0; i < nodeComp.inputs.length; i++) {
      final port = nodeComp.inputs[i];
      final px = pos.x;
      final py = pos.y + (pos.height / (nodeComp.inputs.length + 1)) * (i + 1);
      if (sqrt(pow(hx - px, 2).toDouble() + pow(hy - py, 2).toDouble()) <
          portRadius) {
        return (port: port, x: px, y: py);
      }
    }
    return null;
  }

  Entity? _getConnectionAt(double hx, double hy) {
    final connections =
        world.entities.values.where((e) => e.has<ConnectionComponent>());
    for (final connEntity in connections) {
      final conn = connEntity.get<ConnectionComponent>()!;
      final fromNode = world.entities[conn.fromNodeId]?.get<NodeComponent>();
      final toNode = world.entities[conn.toNodeId]?.get<NodeComponent>();
      if (fromNode == null || toNode == null) continue;

      final start = _getPortPosition(fromNode, conn.fromPortId, true);
      final end = _getPortPosition(toNode, conn.toPortId, false);
      if (start == null || end == null) continue;

      final midX = (start.dx + end.dx) / 2;
      final midY = (start.dy + end.dy) / 2;

      if (sqrt(pow(hx - midX, 2).toDouble() + pow(hy - midY, 2).toDouble()) <
          10.0) {
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
