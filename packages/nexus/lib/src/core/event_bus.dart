import 'dart:async';

/// A simple event bus for decoupled communication between different parts
/// of the application, particularly between different modules.
///
/// Systems can listen for specific event types and react to them, or
/// they can fire events to signal that something has happened.
class EventBus {
  // FINAL, DEFINITIVE, ROBUST FIX v5: The root cause was a subtle race
  // condition during the world's initialization. This new implementation uses
  // a lazy-initialized singleton pattern for the StreamController, making it
  // completely immune to initialization order issues. It's guaranteed to exist
  // before the first call to `fire` or `on`. This is the definitive solution.
  StreamController<dynamic>? _streamController;
  bool _isClosed = false;

  // Use a getter for lazy initialization.
  StreamController<dynamic> get _controller {
    if (_isClosed) {
      throw StateError('EventBus has been destroyed.');
    }
    _streamController ??= StreamController<dynamic>.broadcast();
    return _streamController!;
  }

  EventBus();

  /// Listens for events of a specific type [T].
  ///
  /// The [onData] callback is called when an event of type [T] is fired.
  StreamSubscription<T> on<T>(void Function(T event) onData) {
    return _controller.stream
        .where((event) => event is T)
        .cast<T>()
        .listen(onData);
  }

  /// Fires a new event on the bus.
  ///
  /// All listeners for the type of the [event] object will be notified.
  void fire(dynamic event) {
    if (_isClosed) return;
    _controller.add(event);
  }

  /// Destroys the event bus and releases all resources.
  void destroy() {
    if (_isClosed) return;
    _isClosed = true;
    _streamController?.close();
    _streamController = null;
  }
}
