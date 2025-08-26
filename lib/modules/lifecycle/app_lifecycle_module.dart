// Hide the framework's AppLifecycleSystem to prevent name collision with our custom one.
import 'package:nexus/nexus.dart' hide AppLifecycleSystem;
import 'app_lifecycle_system.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A dedicated Nexus module for handling application lifecycle events.
class AppLifecycleModule extends NexusModule {
  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        // Provide the system that handles lifecycle logic.
        _SingleSystemProvider([AppLifecycleSystem()])
      ];
}
