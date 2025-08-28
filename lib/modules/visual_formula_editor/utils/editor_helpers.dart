// FILE: lib/modules/visual_formula_editor/utils/editor_helpers.dart
// (English comments for code clarity)
// MODIFIED v2.0: Updated operator node creation to start with two dynamic inputs.

import 'dart:math';
import 'dart:ui';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';

// --- Hit Testing Helpers ---

Entity? getNodeAt(NexusWorld world, double hx, double hy) {
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

({NodePort port, double x, double y})? getPortAt(
    Entity node, double hx, double hy) {
  const double portRadius = 10.0;
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

Entity? getConnectionAt(NexusWorld world, double hx, double hy) {
  final connections =
      world.entities.values.where((e) => e.has<ConnectionComponent>());
  for (final connEntity in connections) {
    final conn = connEntity.get<ConnectionComponent>()!;
    final fromNode = world.entities[conn.fromNodeId]?.get<NodeComponent>();
    final toNode = world.entities[conn.toNodeId]?.get<NodeComponent>();
    if (fromNode == null || toNode == null) continue;

    final start = getPortPosition(fromNode, conn.fromPortId, true);
    final end = getPortPosition(toNode, conn.toPortId, false);
    if (start == null || end == null) continue;

    final midX = (start.dx + end.dx) / 2;
    final midY = (start.dy + end.dy) / 2;

    if (sqrt(pow(hx - midX, 2) + pow(hy - midY, 2)) < 10.0) {
      return connEntity;
    }
  }
  return null;
}

Offset? getPortPosition(NodeComponent node, String portId, bool isOutput) {
  final pos = node.position;
  final ports = isOutput ? node.outputs : node.inputs;
  final index = ports.indexWhere((p) => p.id == portId);
  if (index == -1) return null;

  final x = isOutput ? pos.x + pos.width : pos.x;
  final y = pos.y + (pos.height / (ports.length + 1)) * (index + 1);
  return Offset(x, y);
}

// --- Node Factory Helper ---

Entity createNodeFromType(NodeType type, double x, double y) {
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
          data: {'value': 1.0});
      break;
    case NodeType.operator:
      nodeComp = NodeComponent(
          label: '+',
          type: type,
          position: position
            ..width = 80
            ..height = 110, // Adjusted for two initial inputs
          data: {
            'operator': '+'
          },
          inputs: [
            NodePort(id: 'in_0', label: 'A'),
            NodePort(id: 'in_1', label: 'B') // Start with two inputs
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
