// FILE: lib/modules/visual_formula_editor/ui/widgets/node_settings_panel.dart
// (English comments for code clarity)
// MODIFIED v3.0: Added a settings panel for Condition nodes.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

class NodeSettingsPanel extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId nodeId;
  final NodeComponent node;

  const NodeSettingsPanel({
    super.key,
    required this.renderingSystem,
    required this.nodeId,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    switch (node.type) {
      case NodeType.operator:
        return _buildOperatorSettings(context);
      case NodeType.constant:
        return _buildConstantSettings(context);
      case NodeType.input:
        return _buildLabelSettings(context, "ورودی");
      case NodeType.output:
        return _buildLabelSettings(context, "خروجی");
      case NodeType.condition:
        return _buildConditionSettings(context); // Added this case
      default:
        return Container(
          padding: const EdgeInsets.all(20),
          height: 100,
          child: const Center(
              child: Text('تنظیماتی برای این نود وجود ندارد.',
                  style: TextStyle(color: Colors.white))),
        );
    }
  }

  Widget _buildOperatorSettings(BuildContext context) {
    final currentOperator = node.data['operator'] as String? ?? '+';
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تغییر عملگر',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: currentOperator,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            items: ['+', '-', '*', '/']
                .map((op) => DropdownMenuItem(
                    value: op,
                    child: Text(op, style: const TextStyle(fontSize: 24))))
                .toList(),
            onChanged: (newOp) {
              if (newOp != null) {
                renderingSystem.manager?.send(UpdateNodeDataEvent(
                    nodeId: nodeId, newData: {'operator': newOp}));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConstantSettings(BuildContext context) {
    final controller = TextEditingController(
        text: (node.data['value'] as num? ?? 0.0).toString());
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تغییر مقدار ثابت',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54)),
            ),
            onChanged: (value) {
              final double? newValue = double.tryParse(value);
              if (newValue != null) {
                renderingSystem.manager?.send(UpdateNodeDataEvent(
                    nodeId: nodeId, newData: {'value': newValue}));
              }
            },
          )
        ],
      ),
    );
  }

  Widget _buildLabelSettings(BuildContext context, String nodeTypeName) {
    final controller = TextEditingController(text: node.label);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تغییر نام باکس $nodeTypeName',
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'نام جدید',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber)),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                renderingSystem.manager?.send(
                    UpdateNodeDataEvent(nodeId: nodeId, newLabel: value));
              }
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds the settings UI for a Condition node.
  Widget _buildConditionSettings(BuildContext context) {
    final currentOperator = node.data['operator'] as String? ?? '==';
    const operators = ['==', '!=', '>', '<', '>=', '<='];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('تغییر عملگر مقایسه',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: currentOperator,
            dropdownColor: Colors.grey[800],
            style: const TextStyle(color: Colors.white),
            items: operators
                .map((op) => DropdownMenuItem(
                    value: op,
                    child: Text(op,
                        style: const TextStyle(
                            fontSize: 24, fontFamily: 'monospace'))))
                .toList(),
            onChanged: (newOp) {
              if (newOp != null) {
                renderingSystem.manager?.send(UpdateNodeDataEvent(
                    nodeId: nodeId, newData: {'operator': newOp}));
              }
            },
          ),
        ],
      ),
    );
  }
}
