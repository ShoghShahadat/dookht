// FILE: lib/modules/visual_formula_editor/ui/visual_formula_editor_builder.dart
// (English comments for code clarity)
// FIX v4.1: Correctly differentiate between EntityId and NodeComponent instance.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import '../../ui/rendering_system.dart';

class VisualFormulaEditorBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    final viewManagerId = rs.getAllIdsWithTag('view_manager').firstOrNull;
    if (viewManagerId == null) return const SizedBox.shrink();

    final viewState = rs.get<ViewStateComponent>(viewManagerId);
    final activeMethodId = viewState?.activeMethodId;
    if (activeMethodId == null) {
      return const Center(
          child: Text('No method selected for visual editing.'));
    }

    return _VisualFormulaEditorWidget(
      renderingSystem: rs,
      methodId: activeMethodId,
      editorEntityId: entityId,
    );
  }
}

class _VisualFormulaEditorWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId methodId;
  final EntityId editorEntityId;

  const _VisualFormulaEditorWidget(
      {required this.renderingSystem,
      required this.methodId,
      required this.editorEntityId});

  @override
  State<_VisualFormulaEditorWidget> createState() =>
      _VisualFormulaEditorWidgetState();
}

class _VisualFormulaEditorWidgetState
    extends State<_VisualFormulaEditorWidget> {
  Color _getTextColor() {
    final rs = widget.renderingSystem;
    final themeManagerId = rs.getAllIdsWithTag('theme_manager').firstOrNull;
    if (themeManagerId == null) return Colors.white;
    final themeComp = rs.get<ThemeComponent>(themeManagerId);
    return Color(themeComp?.properties['textColor'] as int? ?? 0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.renderingSystem;
    final method = rs.get<PatternMethodComponent>(widget.methodId);
    if (method == null) {
      return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Method not found!')));
    }
    final textColor = _getTextColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('طراحی گرافیکی: ${method.name}',
            style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => rs.manager?.send(ShowMethodManagementEvent()),
        ),
      ),
      body: AnimatedBuilder(
        animation: rs.getNotifier(widget.editorEntityId),
        builder: (context, _) {
          final nodeIds = rs.getAllIdsWithTag('node_component');
          final connectionIds = rs.getAllIdsWithTag('connection_component');
          final canvasState =
              rs.get<EditorCanvasComponent>(widget.editorEntityId);

          return Stack(
            children: [
              GestureDetector(
                onPanStart: (details) {
                  rs.manager?.send(CanvasPointerDownEvent(
                    localX: details.localPosition.dx,
                    localY: details.localPosition.dy,
                  ));
                },
                onPanUpdate: (details) {
                  rs.manager?.send(CanvasPointerMoveEvent(
                    deltaX: details.delta.dx,
                    deltaY: details.delta.dy,
                  ));
                },
                onPanEnd: (details) {
                  rs.manager?.send(CanvasPointerUpEvent());
                },
                child: CustomPaint(
                  painter: _FormulaCanvasPainter(
                    renderingSystem: rs,
                    nodeIds: nodeIds,
                    connectionIds: connectionIds,
                    canvasState: canvasState,
                  ),
                  child: Container(),
                ),
              ),
              _buildToolbar(rs),
              _buildPreviewPanel(rs, nodeIds, canvasState, textColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar(FlutterRenderingSystem rs) {
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
                _buildToolbarButton(Icons.input, 'ورودی', NodeType.input, rs),
                _buildToolbarButton(
                    Icons.pin_outlined, 'ثابت', NodeType.constant, rs),
                _buildToolbarButton(
                    Icons.calculate_outlined, 'عملگر', NodeType.operator, rs),
                _buildToolbarButton(
                    Icons.call_split, 'شرط', NodeType.condition, rs),
                _buildToolbarButton(
                    Icons.output_outlined, 'خروجی', NodeType.output, rs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
      IconData icon, String tooltip, NodeType type, FlutterRenderingSystem rs) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      tooltip: tooltip,
      onPressed: () => rs.manager?.send(AddNodeEvent(type)),
    );
  }

  Widget _buildPreviewPanel(FlutterRenderingSystem rs, List<EntityId> nodeIds,
      EditorCanvasComponent? canvasState, Color textColor) {
    // FIX: Iterate over IDs to keep access to the EntityId
    final inputNodeIds = nodeIds
        .where((id) => rs.get<NodeComponent>(id)?.type == NodeType.input)
        .toList();
    final outputNodeIds = nodeIds
        .where((id) => rs.get<NodeComponent>(id)?.type == NodeType.output)
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
                  // FIX: Map over IDs, not components
                  ...inputNodeIds.map((nodeId) {
                    final node = rs.get<NodeComponent>(nodeId)!;
                    final inputId =
                        node.data['inputId'] as String? ?? nodeId.toString();
                    return _buildPreviewInputField(
                        node.label, inputId, canvasState, rs, textColor);
                  }),
                  const SizedBox(height: 16),
                ],
                Text('خروجی‌ها',
                    style: TextStyle(color: textColor.withOpacity(0.8))),
                // FIX: Map over IDs, not components
                ...outputNodeIds.map((nodeId) {
                  final node = rs.get<NodeComponent>(nodeId)!;
                  final nodeState = rs.get<NodeStateComponent>(nodeId);
                  final value = nodeState?.outputValues['value'];
                  return _buildPreviewOutputField(node.label, value, textColor);
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewInputField(
      String label,
      String inputId,
      EditorCanvasComponent? canvasState,
      FlutterRenderingSystem rs,
      Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        initialValue:
            canvasState?.previewInputValues[inputId]?.toString() ?? '',
        onChanged: (value) {
          rs.manager?.send(UpdatePreviewInputEvent(
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

  Widget _buildPreviewOutputField(
      String label, dynamic value, Color textColor) {
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

class _FormulaCanvasPainter extends CustomPainter {
  final FlutterRenderingSystem renderingSystem;
  final List<EntityId> nodeIds;
  final List<EntityId> connectionIds;
  final EditorCanvasComponent? canvasState;

  _FormulaCanvasPainter({
    required this.renderingSystem,
    required this.nodeIds,
    required this.connectionIds,
    this.canvasState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withOpacity(0.2);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    for (final connectionId in connectionIds) {
      final connComp = renderingSystem.get<ConnectionComponent>(connectionId);
      if (connComp != null) {
        _drawConnection(canvas, connComp);
      }
    }

    _drawDraftConnection(canvas);

    for (final nodeId in nodeIds) {
      final nodeComp = renderingSystem.get<NodeComponent>(nodeId);
      final nodeState = renderingSystem.get<NodeStateComponent>(nodeId);
      if (nodeComp != null) {
        // FIX: Pass the EntityId to the draw methods
        _drawNode(canvas, nodeId, nodeComp, nodeState);
      }
    }
  }

  void _drawNode(Canvas canvas, EntityId nodeId, NodeComponent node,
      NodeStateComponent? state) {
    final pos = node.position;
    final rect = Rect.fromLTWH(pos.x, pos.y, pos.width, pos.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    final nodePaint = Paint()..color = _getColorForNodeType(node.type);
    canvas.drawRRect(rrect, nodePaint);

    String displayValue = '';
    if (state?.errorMessage != null) {
      displayValue = state!.errorMessage!;
    } else if (state?.outputValues.isNotEmpty ?? false) {
      final value = state!.outputValues.values.first;
      if (value is num) {
        displayValue = value.toStringAsFixed(2);
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(children: [
        TextSpan(
            text: node.label,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        if (displayValue.isNotEmpty)
          TextSpan(
              text: '\n$displayValue',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 14)),
      ]),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );
    textPainter.layout(minWidth: 0, maxWidth: pos.width - 16);
    final offset = Offset(rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2);
    textPainter.paint(canvas, offset);

    // FIX: Pass the EntityId to the draw methods
    _drawPorts(canvas, nodeId, node);
  }

  void _drawPorts(Canvas canvas, EntityId nodeId, NodeComponent node) {
    final pos = node.position;
    final portPaint = Paint()..color = Colors.white.withOpacity(0.7);
    final portPaintHighlight = Paint()..color = Colors.amber;

    // Outputs
    for (var i = 0; i < node.outputs.length; i++) {
      final y = pos.y + (pos.height / (node.outputs.length + 1)) * (i + 1);
      // FIX: Compare with nodeId, not node.id
      final isBeingConnected = canvasState?.connectionStartNodeId == nodeId &&
          canvasState?.connectionStartPortId == node.outputs[i].id;
      canvas.drawCircle(Offset(pos.x + pos.width, y), 8.0,
          isBeingConnected ? portPaintHighlight : portPaint);
    }
    // Inputs
    for (var i = 0; i < node.inputs.length; i++) {
      final y = pos.y + (pos.height / (node.inputs.length + 1)) * (i + 1);
      canvas.drawCircle(Offset(pos.x, y), 8.0, portPaint);
    }
  }

  void _drawConnection(Canvas canvas, ConnectionComponent conn) {
    final fromNode = renderingSystem.get<NodeComponent>(conn.fromNodeId);
    final toNode = renderingSystem.get<NodeComponent>(conn.toNodeId);
    if (fromNode == null || toNode == null) return;

    final startPoint = _getPortPosition(fromNode, conn.fromPortId, true);
    final endPoint = _getPortPosition(toNode, conn.toPortId, false);
    if (startPoint == null || endPoint == null) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.cubicTo(startPoint.dx + 50, startPoint.dy, endPoint.dx - 50,
        endPoint.dy, endPoint.dx, endPoint.dy);
    canvas.drawPath(path, paint);
  }

  void _drawDraftConnection(Canvas canvas) {
    if (canvasState?.connectionStartNodeId != null) {
      final startNode = renderingSystem
          .get<NodeComponent>(canvasState!.connectionStartNodeId!);
      if (startNode == null) return;

      final startPoint = _getPortPosition(
          startNode, canvasState!.connectionStartPortId!, true);
      final endPoint = Offset(
          canvasState!.connectionDraftX!, canvasState!.connectionDraftY!);
      if (startPoint == null) return;

      final paint = Paint()
        ..color = Colors.amber
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      path.cubicTo(startPoint.dx + 50, startPoint.dy, endPoint.dx - 50,
          endPoint.dy, endPoint.dx, endPoint.dy);
      canvas.drawPath(path, paint);
    }
  }

  Offset? _getPortPosition(NodeComponent node, String portId, bool isOutput) {
    final pos = node.position;
    final ports = isOutput ? node.outputs : node.inputs;
    final index = ports.indexWhere((p) => p.id == portId);
    if (index == -1) return null;

    final x = isOutput ? pos.x + pos.width : pos.x;
    final y = pos.y + (pos.height / (ports.length + 1)) * (index + 1);
    return Offset(x, y);
  }

  Color _getColorForNodeType(NodeType type) {
    switch (type) {
      case NodeType.input:
        return Colors.blue.shade700.withOpacity(0.8);
      case NodeType.constant:
        return Colors.grey.shade700.withOpacity(0.8);
      case NodeType.operator:
        return Colors.orange.shade800.withOpacity(0.8);
      case NodeType.output:
        return Colors.green.shade700.withOpacity(0.8);
      case NodeType.condition:
        return Colors.purple.shade700.withOpacity(0.8);
    }
  }

  @override
  bool shouldRepaint(covariant _FormulaCanvasPainter oldDelegate) {
    return true;
  }
}
