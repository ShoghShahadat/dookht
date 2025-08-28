// FILE: lib/modules/visual_formula_editor/visual_formula_editor_module.dart
// (English comments for code clarity)
// MODIFIED v3.0: The module no longer creates static nodes. It now includes
// the new lifecycle system responsible for dynamically loading the correct graph.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/formula_evaluation_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_connection_management_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_context_menu_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_gesture_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_interaction_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_node_management_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/editor_state_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/dynamic_port_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/visual_formula_lifecycle_system.dart';

class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

class VisualFormulaEditorModule extends NexusModule {
  @override
  void onLoad(NexusWorld world) {
    // The main entity for the editor page itself.
    final visualEditorPage = Entity()
      ..add(TagsComponent({'visual_formula_editor_page'}))
      ..add(EditorCanvasComponent()) // Initialize with default state
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(visualEditorPage);

    // Node creation is now handled by VisualFormulaLifecycleSystem
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        _SingleSystemProvider([
          // Core editor systems
          EditorGestureSystem(),
          EditorInteractionSystem(),
          EditorNodeManagementSystem(),
          EditorConnectionManagementSystem(),
          EditorContextMenuSystem(),
          EditorStateSystem(),
          DynamicPortSystem(),
          FormulaEvaluationSystem(),
          // New lifecycle system for loading/saving
          VisualFormulaLifecycleSystem(),
        ])
      ];
}
