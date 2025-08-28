// FILE: lib/modules/visual_formula_editor/systems/graph_sync_system.dart
// (English comments for code clarity)
// NEW FILE: This system is responsible for the Graph -> Text data flow.

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
    // RecalculateGraphEvent is fired after any graph modification.
    listen<RecalculateGraphEvent>(_onGraphChanged);
  }

  void _onGraphChanged(RecalculateGraphEvent event) {
    final canvasEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
    if (canvasEntity == null) return;

    final canvasState = canvasEntity.get<EditorCanvasComponent>()!;

    // Generate the new expression from the current graph state.
    final generator = GraphGeneratorSystem(world);
    final newExpression = generator.generate();

    // Update the central canvas state with the new expression.
    // The UI widget will listen to this change and update the text field.
    if (canvasState.currentExpression != newExpression) {
      canvasEntity.add(canvasState.copyWith(currentExpression: newExpression));
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
