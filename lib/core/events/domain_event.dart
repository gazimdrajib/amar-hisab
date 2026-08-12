import 'dart:async';

/// Base class for all domain events (Architecture Book §16.3).
///
/// Domain events are immutable, serialisable objects representing a past
/// business occurrence. Named in the past tense (e.g. `SaleCompleted`).
abstract class DomainEvent {
  DomainEvent({String? eventId, DateTime? timestamp, this.businessId = 0})
      : eventId = eventId ??
            'evt-${DateTime.now().toUtc().microsecondsSinceEpoch}',
        timestamp = (timestamp ?? DateTime.now().toUtc());

  /// Unique event identifier.
  final String eventId;

  /// UTC time the event occurred.
  final DateTime timestamp;

  /// Tenant that produced the event.
  final int businessId;

  Map<String, dynamic> toJson();
}

/// In-memory publish/subscribe bus (Architecture Book §16.2).
///
/// Deliberately simple: broadcast [StreamController]s dispatch events
/// synchronously to in-process subscribers. Events are published **after**
/// the producing database transaction commits (at-most-once delivery).
abstract class EventBus {
  void publish<T extends DomainEvent>(T event);
  Stream<T> on<T extends DomainEvent>();
}

/// Default [EventBus] backed by broadcast stream controllers, one per
/// event type.
class LocalEventBus implements EventBus {
  final Map<Type, StreamController<DomainEvent>> _controllers = {};

  @override
  void publish<T extends DomainEvent>(T event) {
    final controller = _controllers[T];
    if (controller != null && !controller.isClosed) {
      controller.add(event);
    }
  }

  @override
  Stream<T> on<T extends DomainEvent>() {
    final controller = _controllers.putIfAbsent(
      T,
      () => StreamController<DomainEvent>.broadcast(sync: true),
    );
    return controller.stream.where((e) => e is T).cast<T>();
  }

  /// Close all controllers (server shutdown / tests).
  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.close();
    }
    _controllers.clear();
  }
}
