import 'package:nexus/nexus.dart';

// A helper class to satisfy the SystemProvider interface.
class _SingleSystemProvider implements SystemProvider {
  final List<System> _systems;
  _SingleSystemProvider(this._systems);
  @override
  List<System> get systems => _systems;
}

/// A dedicated Nexus module for handling data persistence.
class PersistenceModule extends NexusModule {
  @override
  List<EntityProvider> get entityProviders => [];

  @override
  List<SystemProvider> get systemProviders => [
        // Provide the system that handles saving and loading data.
        _SingleSystemProvider([PersistenceSystem()])
      ];
}
