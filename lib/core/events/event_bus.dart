import 'dart:async';

import 'domain_event.dart';

export 'domain_event.dart' show DomainEvent, LocalEventBus;

/// Publish/subscribe contract for in-process domain events.
///
/// Implementations dispatch events synchronously to in-process subscribers.
/// Events MUST be published **after** the producing database transaction
/// commits (at-most-once delivery; Event Catalog §2).
///
/// Note: the canonical implementations are kept alongside [DomainEvent] in
/// `domain_event.dart` so that `EventBus`/`LocalEventBus` and the event they
/// dispatch share one import-safe location.
typedef EventSubscription = StreamSubscription<DomainEvent>;
