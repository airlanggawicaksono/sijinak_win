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

  @override
  Set<Column> get primaryKey => {userId};
}
