// FILE: lib/modules/ui/transitions/transition_system.dart
// (English comments for code clarity)
// MODIFIED v7.0: CRITICAL REFACTOR - Reverted to the correct two-phase state
// update model. The definitive ViewStateComponent is now updated ONLY at the
// end of the animation in the onComplete callback. This is the correct pattern
// to prevent visual glitches and race conditions.

import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/animation.dart' show Curves;
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
    final viewManager = world.entities.values
        .firstWhereOrNull((e) => e.has<ViewStateComponent>());
    if (viewManager == null) return;

    final viewState = viewManager.get<ViewStateComponent>()!;
    final transitionState = viewManager.get<TransitionComponent>();

    if (transitionState?.isRunning == true) return;
    if (viewState.currentView == event.view) return;

    final oldView = viewState.currentView;
    final newView = event.view;

    // 1. Create the visual transition effect component.
    final nextEffect =
        TransitionType.values[_random.nextInt(TransitionType.values.length)];
    final newTransition = TransitionComponent(
      type: nextEffect,
      oldView: oldView,
      newView: newView,
      isRunning: true,
      progress: 0.0,
    );
    viewManager.add(newTransition);

    // 2. Add an animation component to drive the visual effect.
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
        // 3. AT THE END of the animation, finalize the state change.
        final finalTransition = entity.get<TransitionComponent>()!;
        entity.add(ViewStateComponent(
          currentView: newView, // The definitive state is updated here.
          activeCustomerId: event.customerId ?? viewState.activeCustomerId,
          activeMethodId: event.methodId ?? viewState.activeMethodId,
          activeFormulaKey: event.formulaKey ?? viewState.activeFormulaKey,
        ));

        // Mark the visual effect as complete.
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
