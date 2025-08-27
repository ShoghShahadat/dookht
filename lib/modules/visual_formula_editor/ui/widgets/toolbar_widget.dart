// FILE: lib/modules/visual_formula_editor/ui/widgets/toolbar_widget.dart
// (English comments for code clarity)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';

/// A widget that displays the toolbar for adding new nodes to the canvas.
class ToolbarWidget extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;

  const ToolbarWidget({super.key, required this.renderingSystem});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildToolbarButton(Icons.input, 'ورودی', NodeType.input),
                _buildToolbarButton(
                    Icons.pin_outlined, 'ثابت', NodeType.constant),
                _buildToolbarButton(
                    Icons.calculate_outlined, 'عملگر', NodeType.operator),
                _buildToolbarButton(
                    Icons.call_split, 'شرط', NodeType.condition),
                _buildToolbarButton(
                    Icons.output_outlined, 'خروجی', NodeType.output),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, NodeType type) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
      onPressed: () => renderingSystem.manager?.send(AddNodeEvent(type)),
    );
  }
}
