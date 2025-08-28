// FILE: lib/modules/visual_formula_editor/visual_formula_editor_module.dart
// (English comments for code clarity)
// MODIFIED v4.0: Added the new GraphSyncSystem to the module.

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
import 'package:tailor_assistant/modules/visual_formula_editor/systems/graph_sync_system.dart';
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
    final visualEditorPage = Entity()
      ..add(TagsComponent({'visual_formula_editor_page'}))
      ..add(EditorCanvasComponent())
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(visualEditorPage);
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
          // Lifecycle and Sync systems
          VisualFormulaLifecycleSystem(),
          // NEW: System for Graph -> Text synchronization
          GraphSyncSystem(),
        ])
      ];
}
