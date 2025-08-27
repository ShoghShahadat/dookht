// FILE: lib/modules/lifecycle/app_lifecycle_module.dart
// (English comments for code clarity)
// FINAL, DEFINITIVE FIX v14: The root cause was a race condition with the
// built-in GarbageCollectorSystem. The solution is to disable it and let our
// own AppLifecycleSystem handle the cleanup of the bootstrap entity after
// it has been safely used, ensuring a predictable, linear execution flow.

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
        _SingleSystemProvider([
          // Only our custom system is needed.
          AppLifecycleSystem(),
          // THE FIX: Remove the GarbageCollectorSystem to prevent race conditions.
          // Our AppLifecycleSystem will now be the single source of truth for
          // managing the bootstrap and restoration process.
        ])
      ];
}
