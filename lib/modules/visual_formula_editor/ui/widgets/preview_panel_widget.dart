// FILE: lib/modules/visual_formula_editor/ui/widgets/preview_panel_widget.dart
// (English comments for code clarity)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

/// A widget that displays the real-time preview panel for inputs and outputs.
class PreviewPanelWidget extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;
  final List<EntityId> nodeIds;
  final EditorCanvasComponent? canvasState;
  final Color textColor;

  const PreviewPanelWidget({
    super.key,
    required this.renderingSystem,
    required this.nodeIds,
    required this.canvasState,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final inputNodeIds = nodeIds
        .where((id) =>
            renderingSystem.get<NodeComponent>(id)?.type == NodeType.input)
        .toList();
    final outputNodeIds = nodeIds
        .where((id) =>
            renderingSystem.get<NodeComponent>(id)?.type == NodeType.output)
        .toList();

    return Positioned(
      top: 16,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('پیش‌نمایش لحظه‌ای',
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white24, height: 20),
                if (inputNodeIds.isNotEmpty) ...[
                  Text('ورودی‌ها',
                      style: TextStyle(color: textColor.withOpacity(0.8))),
                  ...inputNodeIds.map((nodeId) {
                    final node = renderingSystem.get<NodeComponent>(nodeId)!;
                    final inputId =
                        node.data['inputId'] as String? ?? nodeId.toString();
                    return _buildPreviewInputField(node.label, inputId);
                  }),
                  const SizedBox(height: 16),
                ],
                Text('خروجی‌ها',
                    style: TextStyle(color: textColor.withOpacity(0.8))),
                ...outputNodeIds.map((nodeId) {
                  final node = renderingSystem.get<NodeComponent>(nodeId)!;
                  final nodeState =
                      renderingSystem.get<NodeStateComponent>(nodeId);
                  final value = nodeState?.outputValues['value'];
                  return _buildPreviewOutputField(node.label, value);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewInputField(String label, String inputId) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        initialValue:
            canvasState?.previewInputValues[inputId]?.toString() ?? '',
        onChanged: (value) {
          renderingSystem.manager?.send(UpdatePreviewInputEvent(
            inputId: inputId,
            value: double.tryParse(value),
          ));
        },
        style: TextStyle(color: textColor),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPreviewOutputField(String label, dynamic value) {
    String displayValue = '-';
    if (value is num) {
      displayValue = value.toStringAsFixed(2);
    } else if (value != null) {
      displayValue = value.toString();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textColor.withOpacity(0.9))),
          Text(displayValue,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
