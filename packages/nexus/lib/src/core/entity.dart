// FILE: packages/nexus/lib/src/core/entity.dart
// (English comments for code clarity)
// FINAL, DEFINITIVE FIX v13: Added an `isNew` flag. When a component is added
// to a new entity, the entity remains marked as new. The isolate manager
// uses this flag to know when to send a full component snapshot instead of
// just a partial "dirty" update, solving the final data sync issue on restoration.

import 'package:flutter/foundation.dart';
import 'package:nexus/src/core/component.dart';

typedef EntityId = int;

class Entity extends ChangeNotifier {
  static int _nextId = 0;
  final EntityId id;
  final Map<Type, Component> _components = {};

  final Set<Type> _dirtyComponents = {};
  Set<Type> get dirtyComponents => Set.unmodifiable(_dirtyComponents);
  void clearDirty() => _dirtyComponents.clear();

  // THE FIX: Add a flag to track if the entity is new.
  bool isNew = true;

  Entity() : id = _nextId++;

  void add<T extends Component>(T component) {
    // When adding a component, if the entity is new, all its components are new.
    // No need to check for dirtiness yet.
    if (isNew) {
      _components[T] = component;
      notifyListeners();
      return;
    }

    final existingComponent = _components[T];

    if (identical(existingComponent, component)) {
      _dirtyComponents.add(T);
      notifyListeners();
      return;
    }

    if (existingComponent != null && existingComponent == component) {
      return;
    }

    _components[T] = component;
    _dirtyComponents.add(T);
    notifyListeners();
  }

  void addComponents(List<Component> components) {
    if (isNew) {
      for (final component in components) {
        _components[component.runtimeType] = component;
      }
      notifyListeners();
      return;
    }

    bool hasChanged = false;
    for (final component in components) {
      final type = component.runtimeType;
      final existingComponent = _components[type];

      if (identical(existingComponent, component)) {
        _dirtyComponents.add(type);
        hasChanged = true;
        continue;
      }

      if (existingComponent != null && existingComponent == component) {
        continue;
      }

      _components[type] = component;
      _dirtyComponents.add(type);
      hasChanged = true;
    }

    if (hasChanged) {
      notifyListeners();
    }
  }

  T? remove<T extends Component>() {
    final removed = _components.remove(T) as T?;
    if (removed != null) {
      notifyListeners();
    }
    return removed;
  }

  Component? removeByType(Type componentType) {
    final removed = _components.remove(componentType);
    if (removed != null) {
      notifyListeners();
    }
    return removed;
  }

  T? get<T extends Component>() {
    return _components[T] as T?;
  }

  Component? getByType(Type componentType) {
    return _components[componentType];
  }

  bool has<T extends Component>() {
    return _components.containsKey(T);
  }

  Iterable<Component> get allComponents => _components.values;

  @override
  String toString() {
    return 'Entity($id, components: ${_components.keys.map((t) => t.toString()).toList()})';
  }
}
