// FILE: lib/modules/visual_formula_editor/systems/text_to_graph_sync_system.dart
// (English comments for code clarity)
// MODIFIED v4.0: Now receives the variable name map from the parser and updates
// the central EditorCanvasComponent with it.

import 'package:collection/collection.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/formula_parser_system.dart';

class TextToGraphSyncSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<UpdateFormulaFromTextEvent>(_onFormulaTextChanged);
  }

  void _onFormulaTextChanged(UpdateFormulaFromTextEvent event) {
    final viewManager = world.entities.values
        .firstWhereOrNull((e) => e.has<ViewStateComponent>());
    if (viewManager == null) return;

    final viewState = viewManager.get<ViewStateComponent>()!;
    final methodId = viewState.activeMethodId;
    final formulaKey = viewState.activeFormulaKey;
    if (methodId == null || formulaKey == null) return;

    _clearCurrentGraph();

    final parser = FormulaParserSystem();
    final result = parser.parse(formulaKey, event.expression);

    for (final entity in result.entities) {
      world.addEntity(entity);
    }

    // Store the new name map in the central canvas state.
    final canvasEntity = world.entities.values
        .firstWhereOrNull((e) => e.has<EditorCanvasComponent>());
    final canvasState = canvasEntity?.get<EditorCanvasComponent>();
    if (canvasEntity != null && canvasState != null) {
      canvasEntity.add(canvasState.copyWith(variableNameMap: result.nameMap));
    }

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
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
