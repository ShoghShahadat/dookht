// FILE: lib/core/fixed_animation_system.dart
// (English comments for code clarity)
// NEW FILE: A robust, project-specific version of the AnimationSystem.
// This version includes delta time clamping to prevent animation glitches
// after long frames or during initial load, ensuring smooth transitions.

import 'dart:async';

import 'package:nexus/nexus.dart';

/// A system that processes [AnimationComponent]s to drive animations.
class FixedAnimationSystem extends System {
  // A max delta time to prevent huge jumps after a pause/lag (e.g., 30 FPS).
  static const double maxDeltaTime = 1.0 / 30.0;

  @override
  bool matches(Entity entity) {
    return entity.has<AnimationComponent>();
  }

  @override
  void update(Entity entity, double dt) {
    final anim = entity.get<AnimationComponent>()!;

    if (!anim.isPlaying || anim.isFinished) {
      return;
    }

    // CRITICAL FIX: Clamp dt to prevent animation from finishing instantly.
    final clampedDt = dt > maxDeltaTime ? maxDeltaTime : dt;

    anim.update(clampedDt); // Use the clamped value
    anim.onUpdate(entity, anim.curvedValue);

    if (anim.isFinished) {
      anim.onComplete?.call(entity);

      if (anim.repeat) {
        anim.reset();
      } else if (anim.removeOnComplete) {
        Future.microtask(() {
          if (world.entities.containsKey(entity.id)) {
            entity.remove<AnimationComponent>();
          }
        });
      }
    }
  }
}
