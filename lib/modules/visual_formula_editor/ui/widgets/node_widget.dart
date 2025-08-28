// FILE: lib/modules/visual_formula_editor/ui/widgets/node_widget.dart
// (English comments for code clarity)
// REFACTORED v5.0: Enabled settings icon for condition nodes.

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '${node.label}\n${_getNodeDisplayValue(nodeState)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            ..._buildPorts(node, isInput: true),
            ..._buildPorts(node, isInput: false),
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

  List<Widget> _buildPorts(NodeComponent node, {required bool isInput}) {
    final ports = isInput ? node.inputs : node.outputs;
    if (ports.isEmpty) return [];

    const double portRadius = 8.0;
    const double portSize = portRadius * 2;

    return List.generate(ports.length, (index) {
      final port = ports[index];
      final topPosition =
          (node.position.height / (ports.length + 1)) * (index + 1);

      return Positioned(
        top: topPosition - portRadius,
        left: isInput ? -portRadius : null,
        right: isInput ? null : -portRadius,
        child: Tooltip(
          message: port.label,
          child: Container(
            width: portSize,
            height: portSize,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withOpacity(0.7), width: 2),
            ),
          ),
        ),
      );
    });
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
    return type == NodeType.operator ||
        type == NodeType.constant ||
        type == NodeType.input ||
        type == NodeType.output ||
        type == NodeType.condition; // Added condition node
  }
}
