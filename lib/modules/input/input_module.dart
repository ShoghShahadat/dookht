import 'package:nexus/nexus.dart';
import 'input_system.dart' hide InputSystem;

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
        // Provide the system that processes tap events.
        _SingleSystemProvider([InputSystem()])
      ];
}
