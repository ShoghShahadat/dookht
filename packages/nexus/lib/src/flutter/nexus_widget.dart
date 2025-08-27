import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nexus/nexus.dart';
import 'package:nexus/src/events/ui_events.dart';

class NexusWidget extends StatefulWidget {
  final NexusWorld Function() worldProvider;
  final FlutterRenderingSystem renderingSystem;
  final Future<void> Function()? isolateInitializer;
  final RootIsolateToken? rootIsolateToken;
  final String Function(Component component) componentTypeIdProvider;

  const NexusWidget({
    super.key,
    required this.worldProvider,
    required this.renderingSystem,
    this.isolateInitializer,
    this.rootIsolateToken,
    required this.componentTypeIdProvider,
  });

  @override
  State<NexusWidget> createState() => _NexusWidgetState();
}

class _NexusWidgetState extends State<NexusWidget> {
  static NexusManager? _staticDebugManager;

  late NexusManager _manager;
  late final AppLifecycleListener _lifecycleListener;
  final FocusNode _focusNode = FocusNode();
  StreamSubscription? _renderPacketSubscription;

  @override
  void initState() {
    super.initState();
    _initializeManager();

    _lifecycleListener = AppLifecycleListener(
      onStateChange: _onLifecycleStateChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode && _manager is NexusSingleThreadManager) {
      final snapshot = (_manager as NexusSingleThreadManager).hydrate();
      widget.renderingSystem.updateFromPackets(snapshot);
      _subscribeToRenderPackets();
    }
  }

  void _onLifecycleStateChanged(AppLifecycleState state) {
    final AppLifecycleStatus status;
    switch (state) {
      case AppLifecycleState.resumed:
        status = AppLifecycleStatus.resumed;
        break;
      case AppLifecycleState.inactive:
        status = AppLifecycleStatus.inactive;
        break;
      case AppLifecycleState.paused:
        status = AppLifecycleStatus.paused;
        break;
      case AppLifecycleState.detached:
        status = AppLifecycleStatus.detached;
        break;
      case AppLifecycleState.hidden:
        status = AppLifecycleStatus.hidden;
        break;
    }
    _manager.send(AppLifecycleEvent(status));
  }

  void _handleKeyEvent(KeyEvent event) {
    _manager.send(ClientKeyboardEvent(
      event.logicalKey,
      event is KeyDownEvent || event is KeyRepeatEvent,
    ));
  }

  void _initializeManager() {
    if (kDebugMode) {
      if (_staticDebugManager == null) {
        _staticDebugManager = NexusSingleThreadManager();
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        _spawnWorld();
      } else {
        _manager = _staticDebugManager!;
        widget.renderingSystem.setManager(_manager);
        _subscribeToRenderPackets();
        reassemble(); // Force a re-sync on hot reload
      }
    } else {
      if (!kIsWeb) {
        _manager = NexusIsolateManager();
      } else {
        _manager = NexusSingleThreadManager();
      }
      widget.renderingSystem.setManager(_manager);
      _spawnWorld();
    }
  }

  void _spawnWorld() {
    if (_staticDebugManager?.world != null && kDebugMode) return;

    _manager.spawn(
      widget.worldProvider,
      isolateInitializer: widget.isolateInitializer,
      rootIsolateToken: widget.rootIsolateToken,
      componentTypeIdProvider: widget.componentTypeIdProvider,
    );
    _subscribeToRenderPackets();
  }

  void _subscribeToRenderPackets() {
    _renderPacketSubscription?.cancel();
    _renderPacketSubscription = _manager.renderPacketStream
        .listen(widget.renderingSystem.updateFromPackets);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _focusNode.dispose();
    _renderPacketSubscription?.cancel();
    if (!kDebugMode) {
      _manager.dispose();
      _staticDebugManager = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_manager.world != null) {
          _manager.send(ScreenResizedEvent(
            newWidth: constraints.maxWidth,
            newHeight: constraints.maxHeight,
            newOrientation: constraints.maxWidth > constraints.maxHeight
                ? ScreenOrientation.landscape
                : ScreenOrientation.portrait,
          ));
        }

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Listener(
            onPointerMove: (event) {
              // Useful for general pointer tracking.
            },
            child: AnimatedBuilder(
              animation: widget.renderingSystem,
              builder: (context, child) {
                return widget.renderingSystem.build(context);
              },
            ),
          ),
        );
      },
    );
  }
}
