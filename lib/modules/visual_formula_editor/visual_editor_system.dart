// FILE: lib/modules/visual_formula_editor/visual_editor_system.dart
// (English comments for code clarity)

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

const double portRadius = 8.0;
const double portMargin = 16.0;

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
  }

  Entity? _getCanvasEntity() {
    return world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
  }

  void _onAddNode(AddNodeEvent event) {
    final newNode = _createNodeFromType(event.type);
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
      // copy other state properties
      panX: canvasState.panX,
      panY: canvasState.panY,
      zoom: canvasState.zoom,
    ));
  }

  void _onPointerDown(CanvasPointerDownEvent event) {
    // ... (rest of the code is unchanged from v2.0)
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    final nodes =
        world.entities.values.where((e) => e.has<NodeComponent>()).toList();

    for (final node in nodes.reversed) {
      final nodeComp = node.get<NodeComponent>()!;
      final pos = nodeComp.position;

      // Check for port hit
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
            previewInputValues: canvasState.previewInputValues,
          ));
        }
        return;
      }

      // Check for node body hit
      if (event.localX >= pos.x &&
          event.localX <= pos.x + pos.width &&
          event.localY >= pos.y &&
          event.localY <= pos.y + pos.height) {
        canvasEntity.add(EditorCanvasComponent(
          draggedEntityId: node.id,
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
    // ... (rest of the code is unchanged from v2.0)
    final canvasEntity = _getCanvasEntity();
    if (canvasEntity == null) return;
    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    // Finalize connection
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

    // Reset all interaction states
    canvasEntity.add(EditorCanvasComponent(
      panX: canvasState.panX,
      panY: canvasState.panY,
      zoom: canvasState.zoom,
      previewInputValues: canvasState.previewInputValues,
      draggedEntityId: null,
      connectionStartNodeId: null,
      connectionStartPortId: null,
      connectionDraftX: null,
      connectionDraftY: null,
    ));
  }

  // Helper methods (_handleNodeDrag, _handleConnectionDraft, _getPortAt) are unchanged from v2.0...
  void _handleNodeDrag(
      EditorCanvasComponent state, CanvasPointerMoveEvent event) {
    final draggedEntity = world.entities[state.draggedEntityId!];
    if (draggedEntity == null) return;
    final nodeComp = draggedEntity.get<NodeComponent>()!;
    final pos = nodeComp.position;

    final newPosition = PositionComponent(
      x: pos.x + event.deltaX,
      y: pos.y + event.deltaY,
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
    canvasEntity.add(EditorCanvasComponent(
        connectionStartNodeId: state.connectionStartNodeId,
        connectionStartPortId: state.connectionStartPortId,
        connectionDraftX: state.connectionDraftX! + event.deltaX,
        connectionDraftY: state.connectionDraftY! + event.deltaY,
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

  Entity _createNodeFromType(NodeType type) {
    final random = Random();
    final position = PositionComponent(
        x: 100 + random.nextDouble() * 200, y: 100 + random.nextDouble() * 200);
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
