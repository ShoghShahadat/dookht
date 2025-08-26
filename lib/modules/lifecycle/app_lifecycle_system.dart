// Hide the conflicting AppLifecycleEvent from the core library as we use our own logic with it.
import 'package:nexus/nexus.dart' hide AppLifecycleEvent;
import 'package:nexus/src/events/app_lifecycle_event.dart';

/// A system that listens for application lifecycle changes and triggers
/// actions, such as saving data when the app goes into the background.
class AppLifecycleSystem extends System {
  @override
  void onAddedToWorld(NexusWorld world) {
    super.onAddedToWorld(world);
    listen<AppLifecycleEvent>(_onLifecycleChange);
  }

  void _onLifecycleChange(AppLifecycleEvent event) {
    // Check if the app is being paused, hidden, or detached.
    final isLosingFocus = event.status == AppLifecycleStatus.paused ||
        event.status == AppLifecycleStatus.detached ||
        event.status == AppLifecycleStatus.hidden;

    if (isLosingFocus) {
      // Fire the built-in SaveDataEvent from the framework.
      world.eventBus.fire(SaveDataEvent());
      print('[AppLifecycleSystem] App is losing focus. Firing SaveDataEvent.');
    }
  }

  @override
  bool matches(Entity entity) => false; // Purely event-driven

  @override
  void update(Entity entity, double dt) {}
}
