// FILE: lib/modules/visual_formula_editor/visual_formula_editor_module.dart
// (English comments for code clarity)

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/formula_evaluation_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/visual_editor_system.dart';

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
    // The main entity for the editor page itself.
    final visualEditorPage = Entity()
      ..add(TagsComponent({'visual_formula_editor_page'}))
      ..add(EditorCanvasComponent(
        // Initialize with a sample input value
        previewInputValues: {'bust_circumference': 92.0},
      ))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(visualEditorPage);

    // Create some sample nodes with ports
    final inputNode = Entity()
      ..add(TagsComponent({'node_component'}))
      ..add(NodeComponent(
        label: 'دور سینه',
        type: NodeType.input,
        position: PositionComponent(x: 50, y: 100, width: 150, height: 80),
        outputs: [NodePort(id: 'value', label: 'مقدار')],
        data: {'inputId': 'bust_circumference'},
      ))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(inputNode);

    final constantNode = Entity()
      ..add(TagsComponent({'node_component'}))
      ..add(NodeComponent(
        label: 'عدد ثابت',
        type: NodeType.constant,
        position: PositionComponent(x: 50, y: 250, width: 150, height: 80),
        outputs: [NodePort(id: 'value', label: 'مقدار')],
        data: {'value': 4.0},
      ))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(constantNode);

    final operatorNode = Entity()
      ..add(TagsComponent({'node_component'}))
      ..add(NodeComponent(
        label: '/',
        type: NodeType.operator,
        position: PositionComponent(x: 300, y: 150, width: 80, height: 100),
        data: {'operator': '/'},
        inputs: [
          NodePort(id: 'a', label: 'A'),
          NodePort(id: 'b', label: 'B'),
        ],
        outputs: [NodePort(id: 'result', label: 'نتیجه')],
      ))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(operatorNode);

    final outputNode = Entity()
      ..add(TagsComponent({'node_component'}))
      ..add(NodeComponent(
        label: 'عرض کادر سینه',
        type: NodeType.output,
        position: PositionComponent(x: 550, y: 150, width: 150, height: 80),
        inputs: [NodePort(id: 'value', label: 'مقدار')],
      ))
      ..add(LifecyclePolicyComponent(isPersistent: true));
    world.addEntity(outputNode);
  }

  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        _SingleSystemProvider([
          VisualEditorSystem(),
          FormulaEvaluationSystem(), // ADDED: The evaluation engine
        ])
      ];
}
