import 'package:drift/drift.dart';

/// Local-only queue of pending writes from sijinak → Hikvision device.
/// BE has no awareness of this table; it exists purely so the operator can
/// keep editing cards offline (or with a dead Hik) and have the work drain
/// eventually.
///
/// `operation`:
///   - `upsert_card`   → upsertPerson (idempotent) + upsertCard (new_rfid)
///   - `delete_card`   → deleteCard (old_rfid). Person also removed because
///                       Hik person with no card serves no purpose.
///   - `delete_person` → deletePerson (full purge after student removal)
///
/// `status`:
///   - `queued`  → eligible for next worker tick
///   - `done`    → completed
///
/// No "dead" state — Hik is local LAN, retries are cheap and infinite.
class HikOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get employeeNo => text()();
  TextColumn get name => text().nullable()();
  TextColumn get oldRfid => text().nullable()();
  TextColumn get newRfid => text().nullable()();
  TextColumn get operation => text()();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer()();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
