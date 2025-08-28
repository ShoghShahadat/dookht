// FILE: lib/modules/visual_formula_editor/systems/editor_node_management_system.dart
// (English comments for code clarity)
// This system manages the lifecycle of nodes.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// Manages the creation and deletion of nodes in the formula graph.
class EditorNodeManagementSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AddNodeEvent>(_onAddNode);
    listen<DeleteNodeEvent>(_onDeleteNode);
  }

  void _onAddNode(AddNodeEvent event) {
    final canvasEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
    final canvasState = canvasEntity?.get<EditorCanvasComponent>();

    // Calculate a good default position based on the current view
    final x = (canvasState != null && canvasState.zoom != 0)
        ? (-canvasState.panX / canvasState.zoom) + 50
        : 100.0;
    final y = (canvasState != null && canvasState.zoom != 0)
        ? (-canvasState.panY / canvasState.zoom) + 50
        : 100.0;

    final newNode = createNodeFromType(event.type, x, y);
    world.addEntity(newNode);
    world.eventBus.fire(RecalculateGraphEvent());
  }

  void _onDeleteNode(DeleteNodeEvent event) {
    // Find all connections attached to the node being deleted.
    final connections = world.entities.values.where((e) {
      final c = e.get<ConnectionComponent>();
      return c != null &&
          (c.fromNodeId == event.nodeId || c.toNodeId == event.nodeId);
    }).toList();

    // Remove the connections first.
    for (final conn in connections) {
      world.removeEntity(conn.id);
    }

    // Then remove the node itself.
    world.removeEntity(event.nodeId);

    // Trigger a graph recalculation.
    world.eventBus.fire(RecalculateGraphEvent());
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven
  @override
  void update(Entity entity, double dt) {}
}
