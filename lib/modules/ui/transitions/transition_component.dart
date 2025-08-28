// FILE: lib/modules/ui/transitions/transition_component.dart
// (English comments for code clarity)
// NEW FILE: Defines the data structures for page transitions.

import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';

/// An enum representing the different types of page transitions available.
enum TransitionType {
  watercolor,
  burnAway,
  glitch,
  pixelate,
  inkSplash,
}

/// A component that holds the state of an active page transition.
/// This component is managed by the TransitionSystem and read by the AppRenderingSystem.
class TransitionComponent extends Component with SerializableComponent {
  /// The type of the current transition effect.
  final TransitionType type;

  /// The progress of the animation, from 0.0 (start) to 1.0 (end).
  final double progress;

  /// The view we are transitioning from.
  final AppView oldView;

  /// The view we are transitioning to.
  final AppView newView;

  /// Whether a transition is currently active.
  final bool isRunning;

  TransitionComponent({
    required this.type,
    this.progress = 0.0,
    required this.oldView,
    required this.newView,
    this.isRunning = false,
  });

  factory TransitionComponent.fromJson(Map<String, dynamic> json) {
    return TransitionComponent(
      type: TransitionType.values[json['type'] as int],
      progress: (json['progress'] as num).toDouble(),
      oldView: AppView.values[json['oldView'] as int],
      newView: AppView.values[json['newView'] as int],
      isRunning: json['isRunning'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type.index,
        'progress': progress,
        'oldView': oldView.index,
        'newView': newView.index,
        'isRunning': isRunning,
      };

  @override
  List<Object?> get props => [type, progress, oldView, newView, isRunning];
}
