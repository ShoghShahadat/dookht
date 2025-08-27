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
  late final String Function(Component component) _componentTypeIdProvider;

  final _renderPacketController =
      StreamController<List<RenderPacket>>.broadcast();
  @override
  Stream<List<RenderPacket>> get renderPacketStream =>
      _renderPacketController.stream;

  @override
  List<RenderPacket> hydrate() {
    if (_world == null) return [];

    final packets = <RenderPacket>[];
    for (final entity in _world!.entities.values) {
      final serializableComponents = <String, Map<String, dynamic>>{};
      for (final component in entity.allComponents) {
        if (component is SerializableComponent) {
          final typeId = _componentTypeIdProvider(component);
          serializableComponents[typeId] =
              (component as SerializableComponent).toJson();
        }
      }
      if (serializableComponents.isNotEmpty) {
        packets.add(
            RenderPacket(id: entity.id, components: serializableComponents));
      }
    }
    return packets;
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
          final typeId = _componentTypeIdProvider(component!);
          serializableComponents[typeId] =
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
    required String Function(Component component) componentTypeIdProvider,
  }) async {
    _componentTypeIdProvider = componentTypeIdProvider;
    if (isolateInitializer != null) {
      await isolateInitializer();
    }
    _world = worldProvider();
    await _world!.init();

    final initialPackets = hydrate();
    if (initialPackets.isNotEmpty) {
      _renderPacketController.add(initialPackets);
    }
    for (final entity in _world!.entities.values) {
      entity.clearDirty();
    }

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
    if (isHotReload && _world != null) {
      _world!.eventBus.fire(SaveDataEvent());
      _updateLoop();
    }
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _world?.clear();
    _world = null;
    await _renderPacketController.close();
  }
}
