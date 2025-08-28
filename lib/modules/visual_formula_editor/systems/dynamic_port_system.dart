// FILE: lib/modules/visual_formula_editor/systems/dynamic_port_system.dart
// (English comments for code clarity)
// REFACTORED v2.0: Correctly reads the PositionComponent from within the NodeComponent,
// which is the proper architectural pattern and fixes the null check error.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_connection_management_system.dart';

/// A system that dynamically adds input ports to operator nodes when the last
/// available port is used, allowing for an "unlimited" number of inputs.
class DynamicPortSystem extends System {
  static const double baseHeight = 40.0;
  static const double portRowHeight = 35.0;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<FinalizeConnectionEvent>(_onConnectionFinalized);
  }

  void _onConnectionFinalized(FinalizeConnectionEvent event) {
    final targetNode = event.targetNode;
    if (targetNode == null || event.targetPort == null) return;

    final nodeComp = targetNode.get<NodeComponent>();
    if (nodeComp == null || nodeComp.type != NodeType.operator) return;

    final lastInputPort = nodeComp.inputs.lastOrNull;
    if (lastInputPort != null && lastInputPort.id == event.targetPort!.id) {
      _addInputPort(targetNode, nodeComp);
    }
  }

  /// Adds a new input port to the node and increases its height.
  void _addInputPort(Entity nodeEntity, NodeComponent nodeComp) {
    final newPortIndex = nodeComp.inputs.length;
    final newPortId = 'in_$newPortIndex';
    final newPortLabel = String.fromCharCode('A'.codeUnitAt(0) + newPortIndex);

    final newInputs = List<NodePort>.from(nodeComp.inputs)
      ..add(NodePort(id: newPortId, label: newPortLabel));

    final newHeight = baseHeight + (newInputs.length * portRowHeight);

    // *** BUG FIX: Get the position from *inside* the NodeComponent ***
    final currentPosition = nodeComp.position;
    final newPosition = currentPosition.copyWith(height: newHeight);

    // Update the node with both the new input list and the new position data.
    nodeEntity.add(nodeComp.copyWith(inputs: newInputs, position: newPosition));
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
