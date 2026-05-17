import 'package:drift/drift.dart';

/// Sijinak-local outbox of card mutations that need to be confirmed by BE.
///
/// Each user edit (single or bulk-import row) inserts one row in `queued`
/// status. A background worker drains queued rows by POSTing to
/// `/api/desktop/students/{uid}/card`. Outcomes:
///   - 2xx              → status='done'
///   - 4xx (validation) → status='dead', local Students.rfid reverted to oldRfid
///   - 5xx / network    → attempts++ with backoff; after MAX_ATTEMPTS marked
///                        'dead' + reverted
///
/// `oldRfid` is snapshotted at enqueue time so we always know what to revert
/// to if BE rejects.
class CardOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get oldRfid => text().nullable()();
  TextColumn get newRfid => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('queued'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer()();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
