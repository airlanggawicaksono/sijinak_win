import 'package:drift/drift.dart';

class TapRecords extends Table {
  TextColumn get id => text()();
  TextColumn get rfidNumber => text()();
  TextColumn get eventType => text()(); // absen_masuk, absen_keluar, izin
  IntColumn get deviceTime => integer()();
  TextColumn get reason => text().nullable()();
  IntColumn get hikSerialNo => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get publishedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {rfidNumber, deviceTime},
      ];
}
