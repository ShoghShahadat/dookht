// FILE: lib/modules/visual_formula_editor/systems/editor_connection_management_system.dart
// (English comments for code clarity)
// This system manages the lifecycle of connections.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

// A new event to decouple gesture system from connection system
class FinalizeConnectionEvent {
  final EntityId fromNodeId;
  final String fromPortId;
  final Entity? targetNode;
  final NodePort? targetPort;

  FinalizeConnectionEvent({
    required this.fromNodeId,
    required this.fromPortId,
    this.targetNode,
    this.targetPort,
  });
}

/// Manages the creation and deletion of connections between nodes.
class EditorConnectionManagementSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<DeleteConnectionEvent>(_onDeleteConnection);
    listen<FinalizeConnectionEvent>(_onFinalizeConnection);
  }

  void _onFinalizeConnection(FinalizeConnectionEvent event) {
    final targetNode = event.targetNode;
    final targetPort = event.targetPort;

    if (targetNode != null &&
        targetPort != null &&
        targetNode.id != event.fromNodeId) {
      // Check if the target port is an input port
      final isInput = targetNode
          .get<NodeComponent>()!
          .inputs
          .any((p) => p.id == targetPort.id);

      if (isInput) {
        final newConnection = Entity()
          ..add(ConnectionComponent(
            fromNodeId: event.fromNodeId,
            fromPortId: event.fromPortId,
            toNodeId: targetNode.id,
            toPortId: targetPort.id,
          ))
          ..add(LifecyclePolicyComponent(isPersistent: true))
          ..add(TagsComponent({'connection_component'}));
        world.addEntity(newConnection);
        world.eventBus.fire(RecalculateGraphEvent());
      }
    }
  }

  void _onDeleteConnection(DeleteConnectionEvent event) {
    world.removeEntity(event.connectionId);
    world.eventBus.fire(RecalculateGraphEvent());
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven
  @override
  void update(Entity entity, double dt) {}
}
