// FILE: lib/modules/visual_formula_editor/visual_formula_editor_module.dart
// (English comments for code clarity)
// MODIFIED v2.0: Added the new DynamicPortSystem to the module's system providers.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/formula_evaluation_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_connection_management_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_context_menu_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_gesture_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_interaction_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_node_management_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_state_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/dynamic_port_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A Nexus module that sets up the entities and systems for the "Visual Formula Editor" page.
class VisualFormulaEditorModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    final visualEditorPage = Entity()
      ..add(TagsComponent({'visual_formula_editor_page'}))
      ..add(EditorCanvasComponent(
        previewInputValues: {'bust_circumference': 92.0},
      ))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(visualEditorPage);

    // Create some sample nodes with ports
    final inputNode = createNodeFromType(NodeType.input, 50, 100);
    world.addEntity(inputNode);

    final constantNode = createNodeFromType(NodeType.constant, 50, 250);
    world.addEntity(constantNode);

    final operatorNode = createNodeFromType(NodeType.operator, 300, 150);
    world.addEntity(operatorNode);

    final outputNode = createNodeFromType(NodeType.output, 550, 150);
    world.addEntity(outputNode);

    Future.microtask(() => world.eventBus.fire(RecalculateGraphEvent()));
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        _SingleSystemProvider([
          EditorGestureSystem(),
          EditorInteractionSystem(),
          EditorNodeManagementSystem(),
          EditorConnectionManagementSystem(),
          EditorContextMenuSystem(),
          EditorStateSystem(),
          DynamicPortSystem(), // Added the new system
          FormulaEvaluationSystem(),
        ])
      ];
}
