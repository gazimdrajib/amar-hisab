import '../../../../core/events/domain_event.dart';

/// Fired after any journal entry (manual or auto) is successfully posted
/// (Event Catalog §3.4 – `JournalPosted`).
class JournalPosted extends DomainEvent {
  JournalPosted({
    required this.entryId,
    required this.entryNumber,
    required this.isAuto,
    this.reference,
    required super.businessId,
  });

  final int entryId;
  final String entryNumber;
  final bool isAuto;
  final String? reference;

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'businessId': businessId,
        'entryId': entryId,
        'entryNumber': entryNumber,
        'isAuto': isAuto,
        'reference': reference,
      };
}
