/// In-memory domain-event bus and categories, mirroring the structure of the
/// Architecture Book §16:
///
///  * `domain_event.dart` – canonical definitions: [DomainEvent],
///    [EventBus], [LocalEventBus].
///  * `event_bus.dart` – the pub/sub contract typedef.
///  * `domain_events.dart` – the cross-module event catalogue.
library;

export 'domain_event.dart';
export 'domain_events.dart';
export 'event_bus.dart';
