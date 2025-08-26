import 'package:tailor_assistant/modules/modules/calculations/calculation_system.dart';
import 'package:nexus/nexus.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A dedicated Nexus module for the calculation feature.
class CalculationModule extends NexusModule {
  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        // Provide the system that handles all calculation logic.
        _SingleSystemProvider([CalculationSystem()])
      ];
}
