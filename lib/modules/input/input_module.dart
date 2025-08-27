// FILE: lib/modules/input/input_module.dart
// (English comments for code clarity)
// FINAL FIX: This module now correctly imports and provides the core InputSystem
// from the Nexus package, removing the problematic 'hide' directive and resolving
// the unresponsive button issue.

import 'package:nexus/nexus.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A dedicated Nexus module for handling user input.
class InputModule extends NexusModule {
  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        // Provide the system that processes tap events directly from the framework.
        _SingleSystemProvider([InputSystem()])
      ];
}
