// FILE: lib/modules/visual_formula_editor/components/editor_components.dart
// (English comments for code clarity)

import 'package:nexus/nexus.dart';

/// Defines the type of a node in the visual editor.
enum NodeType {
  input,
  constant, // ADDED: For constant number values
  operator,
  condition,
  output,
}

/// A helper class defining an input or output port on a node. Not a component.
class NodePort with EquatableMixin {
  final String id;
  final String label;

  NodePort({required this.id, required this.label});

  factory NodePort.fromJson(Map<String, dynamic> json) {
    return NodePort(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  @override
  List<Object?> get props => [id, label];
}

/// A serializable component representing a single node (box) on the canvas.
class NodeComponent extends Component with SerializableComponent {
  final String label;
  final NodeType type;
  final PositionComponent position;
  final Map<String, dynamic> data;
  final List<NodePort> inputs;
  final List<NodePort> outputs;

  NodeComponent({
    required this.label,
    required this.type,
    required this.position,
    this.data = const {},
    this.inputs = const [],
    this.outputs = const [],
  });

  factory NodeComponent.fromJson(Map<String, dynamic> json) {
    return NodeComponent(
      label: json['label'] as String,
      type: NodeType.values[json['type'] as int],
      position: PositionComponent.fromJson(json['position']),
      data: Map<String, dynamic>.from(json['data']),
      inputs: (json['inputs'] as List)
          .map((p) => NodePort.fromJson(p as Map<String, dynamic>))
          .toList(),
      outputs: (json['outputs'] as List)
          .map((p) => NodePort.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'label': label,
        'type': type.index,
        'position': position.toJson(),
        'data': data,
        'inputs': inputs.map((p) => p.toJson()).toList(),
        'outputs': outputs.map((p) => p.toJson()).toList(),
      };

  @override
  List<Object?> get props => [label, type, position, data, inputs, outputs];
}

/// A serializable component representing a connection between two nodes.
class ConnectionComponent extends Component with SerializableComponent {
  final EntityId fromNodeId;
  final String fromPortId;
  final EntityId toNodeId;
  final String toPortId;

  ConnectionComponent({
    required this.fromNodeId,
    required this.fromPortId,
    required this.toNodeId,
    required this.toPortId,
  });

  factory ConnectionComponent.fromJson(Map<String, dynamic> json) {
    return ConnectionComponent(
      fromNodeId: json['fromNodeId'] as EntityId,
      fromPortId: json['fromPortId'] as String,
      toNodeId: json['toNodeId'] as EntityId,
      toPortId: json['toPortId'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'fromNodeId': fromNodeId,
        'fromPortId': fromPortId,
        'toNodeId': toNodeId,
        'toPortId': toPortId,
      };

  @override
  List<Object?> get props => [fromNodeId, fromPortId, toNodeId, toPortId];
}

/// A component to hold the state of the editor canvas itself.
class EditorCanvasComponent extends Component with SerializableComponent {
  final double panX;
  final double panY;
  final double zoom;
  final EntityId? draggedEntityId;

  final EntityId? connectionStartNodeId;
  final String? connectionStartPortId;
  final double? connectionDraftX;
  final double? connectionDraftY;

  // Holds the user-provided values for the preview
  final Map<String, double> previewInputValues;

  EditorCanvasComponent({
    this.panX = 0.0,
    this.panY = 0.0,
    this.zoom = 1.0,
    this.draggedEntityId,
    this.connectionStartNodeId,
    this.connectionStartPortId,
    this.connectionDraftX,
    this.connectionDraftY,
    this.previewInputValues = const {},
  });

  factory EditorCanvasComponent.fromJson(Map<String, dynamic> json) {
    return EditorCanvasComponent(
      panX: (json['panX'] as num).toDouble(),
      panY: (json['panY'] as num).toDouble(),
      zoom: (json['zoom'] as num).toDouble(),
      draggedEntityId: json['draggedEntityId'] as EntityId?,
      connectionStartNodeId: json['connectionStartNodeId'] as EntityId?,
      connectionStartPortId: json['connectionStartPortId'] as String?,
      connectionDraftX: (json['connectionDraftX'] as num?)?.toDouble(),
      connectionDraftY: (json['connectionDraftY'] as num?)?.toDouble(),
      previewInputValues: (json['previewInputValues'] as Map).map(
        (key, value) => MapEntry(key as String, (value as num).toDouble()),
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'panX': panX,
        'panY': panY,
        'zoom': zoom,
        'draggedEntityId': draggedEntityId,
        'connectionStartNodeId': connectionStartNodeId,
        'connectionStartPortId': connectionStartPortId,
        'connectionDraftX': connectionDraftX,
        'connectionDraftY': connectionDraftY,
        'previewInputValues': previewInputValues,
      };

  @override
  List<Object?> get props => [
        panX,
        panY,
        zoom,
        draggedEntityId,
        connectionStartNodeId,
        connectionStartPortId,
        connectionDraftX,
        connectionDraftY,
        previewInputValues,
      ];
}

/// A component to hold the runtime state of a node, like its calculated value.
class NodeStateComponent extends Component with SerializableComponent {
  final Map<String, dynamic> outputValues;
  final String? errorMessage;

  NodeStateComponent({
    this.outputValues = const {},
    this.errorMessage,
  });

  factory NodeStateComponent.fromJson(Map<String, dynamic> json) {
    return NodeStateComponent(
      outputValues: Map<String, dynamic>.from(json['outputValues']),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'outputValues': outputValues,
        'errorMessage': errorMessage,
      };

  @override
  List<Object?> get props => [outputValues, errorMessage];
}
