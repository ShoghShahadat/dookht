// FILE: lib/modules/ui/transitions/transition_system.dart
// (English comments for code clarity)
// MODIFIED v2.0: Added specialized logging.

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/foundation.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/ui/transitions/transition_component.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_system.dart';

/// Manages the lifecycle of page transitions.
class TransitionSystem extends System {
  final Random _random = Random();

  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<RequestViewChangeEvent>(_onRequestViewChange);
  }

  void _onRequestViewChange(RequestViewChangeEvent event) {
    debugPrint(
        "[LOG | TransitionSystem] --> Received RequestViewChangeEvent for view: ${event.view.name}.");
    final viewManager = world.entities.values
        .firstWhereOrNull((e) => e.has<ViewStateComponent>());
    if (viewManager == null) {
      debugPrint(
          "[LOG | TransitionSystem] --! Aborted: ViewManager entity not found.");
      return;
    }

    final viewState = viewManager.get<ViewStateComponent>()!;
    final transitionState = viewManager.get<TransitionComponent>();

    if (transitionState?.isRunning == true) {
      debugPrint(
          "[LOG | TransitionSystem] --! Aborted: A transition is already in progress.");
      return;
    }

    final nextEffect =
        TransitionType.values[_random.nextInt(TransitionType.values.length)];
    debugPrint(
        "[LOG | TransitionSystem] <-- Starting transition from ${viewState.currentView.name} to ${event.view.name} with effect: ${nextEffect.name}.");

    final newTransition = TransitionComponent(
      type: nextEffect,
      oldView: viewState.currentView,
      newView: event.view,
      isRunning: true,
      progress: 0.0,
    );
    viewManager.add(newTransition);

    viewManager.add(AnimationComponent(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      onUpdate: (entity, value) {
        final currentTransition = entity.get<TransitionComponent>()!;
        entity.add(TransitionComponent(
          type: currentTransition.type,
          oldView: currentTransition.oldView,
          newView: currentTransition.newView,
          isRunning: true,
          progress: value,
        ));
      },
      onComplete: (entity) {
        debugPrint(
            "[LOG | TransitionSystem] --- Transition animation complete. Finalizing view state.");
        final finalTransition = entity.get<TransitionComponent>()!;
        entity.add(ViewStateComponent(
          currentView: finalTransition.newView,
          activeCustomerId: event.customerId ?? viewState.activeCustomerId,
          activeMethodId: event.methodId ?? viewState.activeMethodId,
          activeFormulaKey: event.formulaKey ?? viewState.activeFormulaKey,
        ));
        entity.add(TransitionComponent(
          type: finalTransition.type,
          oldView: finalTransition.oldView,
          newView: finalTransition.newView,
          isRunning: false,
          progress: 1.0,
        ));
      },
    ));
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
