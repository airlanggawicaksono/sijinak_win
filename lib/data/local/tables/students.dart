import 'package:drift/drift.dart';

class Students extends Table {
  TextColumn get userId => text()();
  TextColumn get rfidNumber => text().nullable()();
  TextColumn get nama => text()();
  TextColumn get nisn => text().nullable()();
  TextColumn get kelas => text().nullable()();
  TextColumn get noTelpWali => text().nullable()();
  IntColumn get syncedAt => integer().nullable()();
  BoolColumn get hikRegistered => boolean().withDefault(const Constant(false))();
  // Local-only view of how the most recent card mutation is doing:
  //   synced  → BE state matches local
  //   pending → local edit queued in CardOutbox, BE not yet ack'd
  //   failed  → outbox attempt exhausted; local reverted to BE truth
  TextColumn get cardSyncStatus =>
      text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {userId};
}
