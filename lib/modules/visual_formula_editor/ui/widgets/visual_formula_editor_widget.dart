// FILE: lib/modules/visual_formula_editor/ui/widgets/visual_formula_editor_widget.dart
// (English comments for code clarity)
// FIX v1.9: A major architectural fix for the UI layer.
// - Nodes were not appearing due to incorrect Transform logic. The entire interactive layer is now correctly wrapped in a single Transform.
// - The settings icon is now conditionally rendered only for nodes that have settings.

import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/components/editor_components.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/editor_events.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/painters/formula_canvas_painter.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/preview_panel_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/ui/widgets/toolbar_widget.dart';
import 'package:tailor_assistant/modules/visual_formula_editor/utils/editor_helpers.dart';

class VisualFormulaEditorWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId methodId;
  final EntityId editorEntityId;

  const VisualFormulaEditorWidget({
    super.key,
    required this.renderingSystem,
    required this.methodId,
    required this.editorEntityId,
  });

  @override
  State<VisualFormulaEditorWidget> createState() =>
      _VisualFormulaEditorWidgetState();
}

class _VisualFormulaEditorWidgetState extends State<VisualFormulaEditorWidget> {
  EntityId? _currentlyEditingNodeId;

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

    final nodeIds = rs.getAllIdsWithTag('node_component');
    final connectionIds = rs.getAllIdsWithTag('connection_component');

    final allNotifiers = <Listenable>[
      rs.getNotifier(widget.editorEntityId),
      ...nodeIds.map((id) => rs.getNotifier(id)),
      ...connectionIds.map((id) => rs.getNotifier(id)),
    ];
    final mergedListenable = Listenable.merge(allNotifiers);

    return Scaffold(
      backgroundColor: Colors.black,
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
        animation: mergedListenable,
        builder: (context, _) {
          final canvasState =
              rs.get<EditorCanvasComponent>(widget.editorEntityId);

          if (canvasState == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (canvasState.settingsNodeId != null &&
              canvasState.settingsNodeId != _currentlyEditingNodeId) {
            _currentlyEditingNodeId = canvasState.settingsNodeId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showSettingsBottomSheet(
                    context, rs, canvasState.settingsNodeId!);
              }
            });
          } else if (canvasState.settingsNodeId == null &&
              _currentlyEditingNodeId != null) {
            _currentlyEditingNodeId = null;
          }

          // FIX: The entire interactive layer is now wrapped in a single Transform.
          final transformMatrix = Matrix4.identity()
            ..translate(canvasState.panX, canvasState.panY)
            ..scale(canvasState.zoom);

          return Stack(
            children: [
              GestureDetector(
                onScaleStart: (details) {
                  rs.manager?.send(CanvasScaleStartEvent(
                    focalX: details.localFocalPoint.dx,
                    focalY: details.localFocalPoint.dy,
                  ));
                },
                onScaleUpdate: (details) {
                  rs.manager?.send(CanvasScaleUpdateEvent(
                    focalX: details.localFocalPoint.dx,
                    focalY: details.localFocalPoint.dy,
                    scale: details.scale,
                    deltaX: details.focalPointDelta.dx,
                    deltaY: details.focalPointDelta.dy,
                  ));
                },
                onScaleEnd: (details) {
                  rs.manager?.send(CanvasScaleEndEvent());
                },
                onTapUp: (details) {
                  rs.manager?.send(CanvasTapUpEvent(
                      localX: details.localPosition.dx,
                      localY: details.localPosition.dy));
                },
                onLongPressStart: (details) {
                  rs.manager?.send(CanvasLongPressStartEvent(
                      localX: details.localPosition.dx,
                      localY: details.localPosition.dy));
                },
                child: Transform(
                  transform: transformMatrix,
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CustomPaint(
                        painter: FormulaCanvasPainter(
                          renderingSystem: rs,
                          connectionIds: connectionIds,
                          canvasState: canvasState,
                        ),
                        child: const SizedBox.expand(),
                      ),
                      ..._buildInteractiveLayer(
                          context, rs, nodeIds, connectionIds, canvasState),
                    ],
                  ),
                ),
              ),
              ToolbarWidget(renderingSystem: rs),
              PreviewPanelWidget(
                renderingSystem: rs,
                nodeIds: nodeIds,
                canvasState: canvasState,
                textColor: textColor,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildInteractiveLayer(
      BuildContext context,
      FlutterRenderingSystem rs,
      List<EntityId> nodeIds,
      List<EntityId> connectionIds,
      EditorCanvasComponent canvasState) {
    return [
      ...nodeIds.map((id) => _buildNodeWidget(context, rs, id, canvasState)),
      ...connectionIds
          .map((id) => _buildConnectionWidget(context, rs, id, canvasState)),
    ];
  }

  Widget _buildNodeWidget(BuildContext context, FlutterRenderingSystem rs,
      EntityId nodeId, EditorCanvasComponent canvasState) {
    final node = rs.get<NodeComponent>(nodeId);
    final nodeState = rs.get<NodeStateComponent>(nodeId);
    if (node == null) return const SizedBox.shrink();

    final pos = node.position;
    final isSelected = canvasState.selectedEntityId == nodeId;

    return Positioned(
      left: pos.x,
      top: pos.y,
      width: pos.width,
      height: pos.height,
      child: GestureDetector(
        onTap: () => rs.manager?.send(SelectEntityEvent(nodeId)),
        onScaleStart: (details) => rs.manager?.send(CanvasScaleStartEvent(
            focalX: details.localFocalPoint.dx,
            focalY: details.localFocalPoint.dy)),
        onScaleUpdate: (details) => rs.manager?.send(CanvasScaleUpdateEvent(
            focalX: details.localFocalPoint.dx,
            focalY: details.localFocalPoint.dy,
            scale: 1.0,
            deltaX: details.focalPointDelta.dx,
            deltaY: details.focalPointDelta.dy)),
        onScaleEnd: (details) => rs.manager?.send(CanvasScaleEndEvent()),
        child: Container(
          decoration: BoxDecoration(
              color: _getColorForNodeType(node.type),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? Colors.amber : Colors.white.withOpacity(0.5),
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
              // FIX: Conditionally render the settings icon
              if (_nodeHasSettings(node.type))
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () =>
                        rs.manager?.send(OpenNodeSettingsEvent(nodeId)),
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
      ),
    );
  }

  Widget _buildConnectionWidget(BuildContext context, FlutterRenderingSystem rs,
      EntityId connId, EditorCanvasComponent canvasState) {
    final conn = rs.get<ConnectionComponent>(connId);
    if (conn == null) return const SizedBox.shrink();

    final fromNode = rs.get<NodeComponent>(conn.fromNodeId);
    final toNode = rs.get<NodeComponent>(conn.toNodeId);
    if (fromNode == null || toNode == null) return const SizedBox.shrink();

    final start = getPortPosition(fromNode, conn.fromPortId, true);
    final end = getPortPosition(toNode, conn.toPortId, false);
    if (start == null || end == null) return const SizedBox.shrink();

    final midPoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final isSelected = canvasState.selectedEntityId == connId;

    if (!isSelected) return const SizedBox.shrink();

    return Positioned(
      left: midPoint.dx - 12,
      top: midPoint.dy - 12,
      child: GestureDetector(
        onTap: () => rs.manager?.send(DeleteConnectionEvent(connId)),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
              color: Colors.redAccent, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(
      BuildContext context, FlutterRenderingSystem rs, EntityId nodeId) {
    final node = rs.get<NodeComponent>(nodeId);
    if (node == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => _buildSettingsContent(rs, nodeId, node),
    ).whenComplete(() {
      rs.manager?.send(CloseNodeSettingsEvent());
      _currentlyEditingNodeId = null;
    });
  }

  Widget _buildSettingsContent(
      FlutterRenderingSystem rs, EntityId nodeId, NodeComponent node) {
    switch (node.type) {
      case NodeType.operator:
        return _buildOperatorSettings(rs, nodeId, node);
      case NodeType.constant:
        return _buildConstantSettings(rs, nodeId, node);
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

  Widget _buildOperatorSettings(
      FlutterRenderingSystem rs, EntityId nodeId, NodeComponent node) {
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
                rs.manager?.send(UpdateNodeDataEvent(
                    nodeId: nodeId, newData: {'operator': newOp}));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConstantSettings(
      FlutterRenderingSystem rs, EntityId nodeId, NodeComponent node) {
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
                rs.manager?.send(UpdateNodeDataEvent(
                    nodeId: nodeId, newData: {'value': newValue}));
              }
            },
          )
        ],
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
