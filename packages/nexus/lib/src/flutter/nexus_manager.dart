import 'dart:async';
import 'dart:ui';
import 'package:nexus/nexus.dart';

/// An abstract interface for managing the NexusWorld lifecycle and communication.
abstract class NexusManager {
  Stream<List<RenderPacket>> get renderPacketStream;

  /// Provides access to the world instance, primarily for debug/single-thread mode.
  /// Returns null if the world is in a separate isolate.
  NexusWorld? get world;

  /// A method to get a snapshot of the current state of the world.
  /// Used for hot reload in single-threaded mode.
  List<RenderPacket> hydrate();

  Future<void> spawn(
    NexusWorld Function() worldProvider, {
    Future<void> Function()? isolateInitializer,
    RootIsolateToken? rootIsolateToken,
    required String Function(Component component) componentTypeIdProvider,
  });

  void send(dynamic message);

  Future<void> dispose({bool isHotReload = false});
}
