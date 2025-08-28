// FILE: lib/modules/visual_formula_editor/systems/visual_formula_lifecycle_system.dart
// (English comments for code clarity)
// MODIFIED v5.0: Added extensive debug logging to trace the loading process.

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/formula_parser_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/systems/graph_generator_system.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

/// Manages loading the correct visual graph when the editor is opened,
/// and saving it (and its text equivalent) when the editor is closed.
class VisualFormulaLifecycleSystem extends System {
  EntityId? _activeMethodId;
  String? _activeFormulaKey;

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<ComponentUpdatedEvent<ViewStateComponent>>(_onViewChanged);
  }

  void _onViewChanged(ComponentUpdatedEvent<ViewStateComponent> event) {
    final viewState = event.component;

    final isEnteringEditor =
        viewState.currentView == AppView.visualFormulaEditor;
    final hasActiveFormula = _activeMethodId != null;
    final isNewFormula = viewState.activeMethodId != _activeMethodId ||
        viewState.activeFormulaKey != _activeFormulaKey;

    if (isEnteringEditor && isNewFormula) {
      debugPrint("[VFLifecycle] ➡️ Entering editor for a new formula.");
      _activeMethodId = viewState.activeMethodId;
      _activeFormulaKey = viewState.activeFormulaKey;
      _loadGraphForActiveFormula();
    } else if (!isEnteringEditor && hasActiveFormula) {
      debugPrint("[VFLifecycle] ⬅️ Exiting editor. Saving graph.");
      _saveGraphAndUnload();
    }
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

    if (nodeIds.isNotEmpty || connectionIds.isNotEmpty) {
      debugPrint(
          "[VFLifecycle] 🧹 Clearing ${nodeIds.length} nodes and ${connectionIds.length} connections.");
      for (final id in [...nodeIds, ...connectionIds]) {
        world.removeEntity(id);
      }
    }
  }

  void _loadGraphForActiveFormula() {
    if (_activeMethodId == null || _activeFormulaKey == null) {
      debugPrint(
          "[VFLifecycle] ❌ Load failed: Active method or formula key is null.");
      return;
    }

    _clearCurrentGraph();

    final methodEntity = world.entities[_activeMethodId!];
    final methodComp = methodEntity?.get<PatternMethodComponent>();
    if (methodComp == null) {
      debugPrint(
          "[VFLifecycle] ❌ Load failed: Could not find method entity with ID $_activeMethodId.");
      return;
    }

    final formula = methodComp.formulas
        .firstWhereOrNull((f) => f.resultKey == _activeFormulaKey);
    if (formula == null) {
      debugPrint(
          "[VFLifecycle] ❌ Load failed: Could not find formula with key '$_activeFormulaKey' in method '${methodComp.name}'.");
      return;
    }

    debugPrint(
        "[VFLifecycle] 🔎 Found formula '${formula.label}' with key '${formula.resultKey}'.");
    debugPrint("[VFLifecycle]  EXPRESSION: '${formula.expression}'");
    debugPrint(
        "[VFLifecycle] HAS_GRAPH_DATA: ${formula.visualGraphData != null}");

    List<Entity> newEntities = [];
    if (formula.visualGraphData != null &&
        formula.visualGraphData!['nodes'] != null &&
        (formula.visualGraphData!['nodes'] as List).isNotEmpty) {
      debugPrint("[VFLifecycle] 📈 Deserializing from existing graph data...");
      newEntities = _deserializeGraph(formula.visualGraphData!);
    } else if (formula.expression.trim().isNotEmpty) {
      debugPrint("[VFLifecycle] 📝 Parsing from expression string...");
      final parser = FormulaParserSystem(world, methodComp.variables);
      newEntities = parser.parse(formula.resultKey, formula.expression);
    } else {
      debugPrint(
          "[VFLifecycle] 💡 No data found. Creating a fresh output node.");
      final outputNode = createNodeFromType(NodeType.output, 800, 250)
        ..get<NodeComponent>()!.data['resultKey'] = formula.resultKey;
      newEntities.add(outputNode);
    }

    debugPrint(
        "[VFLifecycle] ✅ Adding ${newEntities.length} new entities to the world for the graph.");
    for (final entity in newEntities) {
      world.addEntity(entity);
    }
  }

  void _saveGraphAndUnload() {
    if (_activeMethodId == null || _activeFormulaKey == null) return;

    debugPrint(
        "[VFLifecycle] 💾 Saving graph for '$_activeFormulaKey' and unloading...");

    final generator = GraphGeneratorSystem(world);
    final newExpression = generator.generate();
    final serializedGraph = _serializeGraph();

    debugPrint("[VFLifecycle] 💾 Generated Expression: '$newExpression'");
    debugPrint(
        "[VFLifecycle] 💾 Serialized Graph contains ${serializedGraph['nodes']?.length ?? 0} nodes.");

    final methodEntity = world.entities[_activeMethodId!];
    final methodComp = methodEntity?.get<PatternMethodComponent>();
    if (methodComp != null) {
      final newFormulas = methodComp.formulas.map((f) {
        if (f.resultKey == _activeFormulaKey) {
          return f.copyWith(
            expression: newExpression,
            visualGraphData: serializedGraph,
          );
        }
        return f;
      }).toList();

      world.eventBus.fire(UpdatePatternMethodEvent(
        methodId: _activeMethodId!,
        newName: methodComp.name,
        newVariables: methodComp.variables,
        newFormulas: newFormulas,
      ));
    }

    _clearCurrentGraph();
    _activeMethodId = null;
    _activeFormulaKey = null;
  }

  Map<String, dynamic> _serializeGraph() {
    final nodes =
        world.entities.values.where((e) => e.has<NodeComponent>()).map((e) {
      final json = e.get<NodeComponent>()!.toJson();
      json['id'] = e.id;
      return json;
    }).toList();
    final connections = world.entities.values
        .where((e) => e.has<ConnectionComponent>())
        .map((e) => e.get<ConnectionComponent>()!.toJson())
        .toList();
    return {'nodes': nodes, 'connections': connections};
  }

  List<Entity> _deserializeGraph(Map<String, dynamic> graphData) {
    final entities = <Entity>[];
    final idMap = <EntityId, EntityId>{};

    if (graphData['nodes'] is List) {
      for (var nodeJson in graphData['nodes']) {
        final oldId = nodeJson['id'] as EntityId;
        final node = Entity()..add(NodeComponent.fromJson(nodeJson));
        idMap[oldId] = node.id;
        entities.add(node);
      }
    }

    if (graphData['connections'] is List) {
      for (var connJson in graphData['connections']) {
        final connComp = ConnectionComponent.fromJson(connJson);
        final newFromId = idMap[connComp.fromNodeId];
        final newToId = idMap[connComp.toNodeId];

        if (newFromId != null && newToId != null) {
          final connection = Entity()
            ..add(ConnectionComponent(
              fromNodeId: newFromId,
              fromPortId: connComp.fromPortId,
              toNodeId: newToId,
              toPortId: connComp.toPortId,
            ))
            ..add(TagsComponent({'connection_component'}));
          entities.add(connection);
        }
      }
    }
    return entities;
  }

  @override
  bool matches(Entity entity) => false;

  @override
  void update(Entity entity, double dt) {}
}
