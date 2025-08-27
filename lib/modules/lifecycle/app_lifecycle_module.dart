// FILE: lib/modules/lifecycle/app_lifecycle_module.dart
// (English comments for code clarity)
// FINAL, DEFINITIVE FIX v3: The Garbage Collector is now correctly disabled.

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
          AppLifecycleSystem(),
          // **THE FINAL FIX**: The Garbage Collector was prematurely deleting loaded entities.
          // For this application, where all entities should be persistent,
          // disabling it is the correct and most robust solution.
          GarbageCollectorSystem(enabled: false),
        ])
      ];
}
