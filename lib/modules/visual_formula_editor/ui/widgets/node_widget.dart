// FILE: lib/modules/visual_formula_editor/ui/widgets/node_widget.dart
// (English comments for code clarity)
// REFACTORED v2.0: Removed the internal GestureDetector. All gestures are now
// handled by the parent InteractiveCanvasLayer to prevent conflicts.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

class NodeWidget extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId nodeId;
  final EditorCanvasComponent canvasState;

  const NodeWidget({
    super.key,
    required this.renderingSystem,
    required this.nodeId,
    required this.canvasState,
  });

  @override
  Widget build(BuildContext context) {
    final node = renderingSystem.get<NodeComponent>(nodeId);
    final nodeState = renderingSystem.get<NodeStateComponent>(nodeId);
    if (node == null) return const SizedBox.shrink();

    final pos = node.position;
    final isSelected = canvasState.selectedEntityId == nodeId;

    // The Positioned widget places the node on the canvas.
    // The gesture handling is now deferred to the parent canvas.
    return Positioned(
      left: pos.x,
      top: pos.y,
      width: pos.width,
      height: pos.height,
      child: Container(
        decoration: BoxDecoration(
            color: _getColorForNodeType(node.type),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.amber : Colors.white.withOpacity(0.5),
              width: isSelected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2)
            ]),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                '${node.label}\n${_getNodeDisplayValue(nodeState)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (_nodeHasSettings(node.type))
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: () => renderingSystem.manager
                      ?.send(OpenNodeSettingsEvent(nodeId)),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.settings,
                        color: Colors.white, size: 16),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  String _getNodeDisplayValue(NodeStateComponent? state) {
    if (state?.errorMessage != null) {
      return state!.errorMessage!;
    } else if (state?.outputValues.isNotEmpty ?? false) {
      final value = state!.outputValues.values.first;
      if (value is num) {
        return value.toStringAsFixed(2);
      }
    }
    return '';
  }

  Color _getColorForNodeType(NodeType type) {
    switch (type) {
      case NodeType.input:
        return Colors.blue.shade700;
      case NodeType.constant:
        return Colors.grey.shade700;
      case NodeType.operator:
        return Colors.orange.shade800;
      case NodeType.output:
        return Colors.green.shade700;
      case NodeType.condition:
        return Colors.purple.shade700;
    }
  }

  bool _nodeHasSettings(NodeType type) {
    return type == NodeType.operator || type == NodeType.constant;
  }
}
