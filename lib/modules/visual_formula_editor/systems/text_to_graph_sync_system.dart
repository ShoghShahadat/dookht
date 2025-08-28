// FILE: lib/modules/visual_formula_editor/systems/text_to_graph_sync_system.dart
// (English comments for code clarity)
// NEW FILE: This system handles the Text -> Graph data flow.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/formula_parser_system.dart';

/// A system that listens for changes in the formula text editor and
/// regenerates the visual graph accordingly.
class TextToGraphSyncSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdateFormulaFromTextEvent>(_onFormulaTextChanged);
  }

  void _onFormulaTextChanged(UpdateFormulaFromTextEvent event) {
    // 1. Get necessary state information
    final viewManager = world.entities.values
        .firstWhereOrNull((e) => e.has<ViewStateComponent>());
    if (viewManager == null) return;

    final viewState = viewManager.get<ViewStateComponent>()!;
    final methodId = viewState.activeMethodId;
    final formulaKey = viewState.activeFormulaKey;
    if (methodId == null || formulaKey == null) return;

    final methodEntity = world.entities[methodId];
    final methodComp = methodEntity?.get<PatternMethodComponent>();
    if (methodComp == null) return;

    // 2. Clear the current graph
    _clearCurrentGraph();

    // 3. Parse the new expression and create new graph entities
    final parser = FormulaParserSystem(world, methodComp.variables);
    final newEntities = parser.parse(formulaKey, event.expression);

    // 4. Add the new entities to the world
    for (final entity in newEntities) {
      world.addEntity(entity);
    }

    // 5. Trigger a recalculation to update node states and sync back to text
    // (This also ensures the expression is formatted correctly after parsing)
    world.eventBus.fire(RecalculateGraphEvent());
  }

  void _clearCurrentGraph() {
    final nodeIds = world.entities.values
        .where((e) => e.has<NodeComponent>())
        .map((e) => e.id)
        .toList();
    final connectionIds = world.entities.values
        .where((e) => e.has<ConnectionComponent>())
        .map((e) => e.id)
        .toList();

    for (final id in [...nodeIds, ...connectionIds]) {
      world.removeEntity(id);
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
