import 'dart:async';
import 'dart:ui';
import 'package:flutter/scheduler.dart';
import 'package:nexus/nexus.dart';

class NexusSingleThreadManager implements NexusManager {
  NexusWorld? _world;
  @override
  NexusWorld? get world => _world;

  Ticker? _ticker;
  final _stopwatch = Stopwatch();

  final _renderPacketController =
      StreamController<List<RenderPacket>>.broadcast();
  @override
  Stream<List<RenderPacket>> get renderPacketStream =>
      _renderPacketController.stream;

  /// *** NEW: Implements the hydrate method for single-threaded mode. ***
  /// It creates a complete snapshot of the world and pushes it to the stream.
  @override
  void hydrate() {
    if (_world == null) return;

    final packets = <RenderPacket>[];
    for (final entity in _world!.entities.values) {
      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          serializableComponents[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      if (serializableComponents.isNotEmpty) {
        packets.add(
            RenderPacket(id: entity.id, components: serializableComponents));
      }
    }

    if (packets.isNotEmpty) {
      _renderPacketController.add(packets);
    }
  }

  void _updateLoop() {
    if (_world == null) return;
    final dt =
        _stopwatch.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    _stopwatch.reset();
    _world!.update(dt);
    final packets = <RenderPacket>[];
    for (final entity in _world!.entities.values) {
      if (entity.dirtyComponents.isEmpty) continue;
      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final componentType in entity.dirtyComponents) {
        final component = entity.getByType(componentType);
        if (component is SerializableComponent) {
          serializableComponents[component.runtimeType.toString()] =
              (component as SerializableComponent).toJson();
        }
      }
      if (serializableComponents.isNotEmpty) {
        packets.add(
            RenderPacket(id: entity.id, components: serializableComponents));
      }
    }
    final removedEntityIds = _world!.getAndClearRemovedEntities();
    for (final id in removedEntityIds) {
      packets.add(RenderPacket(id: id, components: {}, isRemoved: true));
    }
    if (packets.isNotEmpty) {
      _renderPacketController.add(packets);
    }
    for (final entity in _world!.entities.values) {
      entity.clearDirty();
    }
  }

  @override
  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
  }) async {
    if (isolateInitializer != null) {
      await isolateInitializer();
    }
    _world = worldProvider();
    await _world!.init();
    _stopwatch.start();
    _ticker = Ticker((_) => _updateLoop());
    _ticker!.start();
  }

  @override
  void send(dynamic message) {
    _world?.eventBus.fire(message);
  }

  @override
  Future<void> dispose({bool isHotReload = false}) async {
    // In single-threaded mode, hot reload is less of an issue,
    // but we respect the flag for consistency.
    if (isHotReload) {
      _world?.eventBus.fire(SaveDataEvent());
      _updateLoop();
      return;
    }

    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _world?.clear();
    _world = null;
    await _renderPacketController.close();
  }
}
