// FILE: lib/modules/visual_formula_editor/systems/graph_sync_system.dart
// (English comments for code clarity)
// MODIFIED v3.0: Now passes the variable name map from the canvas state
// to the GraphGeneratorSystem.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/graph_generator_system.dart';

/// A system that listens for any changes to the graph structure and regenerates
/// the textual formula, keeping the UI text editor in sync.
class GraphSyncSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<RecalculateGraphEvent>(_onGraphChanged);
  }

  void _onGraphChanged(RecalculateGraphEvent event) {
    final canvasEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
    if (canvasEntity == null) return;

    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    // Pass the name map to the generator.
    final generator = GraphGeneratorSystem(world, canvasState.variableNameMap);
    final newExpression = generator.generate();

    if (canvasState.currentExpression != newExpression) {
      canvasEntity.add(canvasState.copyWith(currentExpression: newExpression));
    }
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
