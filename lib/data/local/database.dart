import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../hikvision/isapi_client.dart' show hikvisionEmployeeNoFor;
import 'tables/card_outbox.dart';
import 'tables/hik_outbox.dart';
import 'tables/students.dart';
import 'tables/tap_records.dart';

part 'database.g.dart';

const _uuid = Uuid();

abstract class StudentStorePort {
  Future<List<Student>> getAllStudents();
  Future<int> getStudentCount();
  Future<Student?> getStudentByCard(String rfidNumber);
  Future<Student?> getStudentByUserId(String userId);
  Future<Student?> getStudentByNisn(String nisn);
  Future<void> upsertStudents(List<StudentsCompanion> rows);
  Future<StudentSnapshotSyncResult> syncStudentsSnapshot({
    required List<StudentsCompanion> rows,
    required Set<String> serverUserIds,
    Set<String> protectedUserIds,
  });
  Future<List<Student>> getUnregisteredStudents();
  Future<void> markHikRegistered(String userId);
  Future<void> assignCardToStudent(String userId, String rfidNumber);
  Future<void> removeCardFromStudent(String userId);
  Future<String> enqueueCardWrite({
    required String userId,
    required String? oldRfid,
    required String? newRfid,
  });
  Future<String?> enqueueHikWrite({
    required String userId,
    required String employeeNo,
    required String operation,
    String? name,
    String? oldRfid,
    String? newRfid,
  });
  Future<void> setStudentCardSyncStatus(String userId, String status);
}

abstract class AttendanceStorePort {
  Future<Student?> getStudentByUserId(String userId);
  Future<Student?> getStudentByCard(String rfidNumber);
  Future<List<TapRecord>> getTodayRecordsForStudent(String userId);
  Future<List<TapRecord>> getTodayRecordsForCard(String rfidNumber);
}

abstract class AbsensiInvalidatorPort {
  /// Drops local TapRecords for [userId] whose deviceTime falls within
  /// [date]'s wall-clock day. Used to invalidate "already signed off" locks
  /// after BE-side absensi mutations.
  Future<int> dropTapRecordsForUserOnDate(String userId, DateTime date);
}

abstract class StudentDeletionPort {
  /// Removes the local Drift row for [userId] and any unpublished TapRecords
  /// belonging to that user (kills the infinite retry loop that would
  /// otherwise re-push attendance to a now-deleted user).
  Future<void> forgetStudent(String userId);
}

/// Three operations sijinak can ask its Hikvision device to perform.
/// Wire format: stored in `HikOutbox.operation` as one of these strings.
class HikOpType {
  static const String upsertCard = 'upsert_card';
  static const String deleteCard = 'delete_card';
  static const String deletePerson = 'delete_person';
}

abstract class HikOutboxPort {
  /// Enqueue a Hik write. No-op (returns null) when the requested change
  /// would be a no-op (e.g. card transitioning null → null).
  Future<String?> enqueueHikWrite({
    required String userId,
    required String employeeNo,
    required String operation,
    String? name,
    String? oldRfid,
    String? newRfid,
  });

  Future<List<HikOutboxData>> dueHikOutboxRows({required int nowSec, int limit = 20});

  Future<void> markHikOutboxDone(String id);

  Future<void> bumpHikOutboxRetry({
    required String id,
    required int attempts,
    required int nextAttemptAt,
    required String error,
  });
}

abstract class CardOutboxPort {
  /// Enqueue a card mutation. The worker drains rows asynchronously.
  /// Returns the outbox row id.
  Future<String> enqueueCardWrite({
    required String userId,
    required String? oldRfid,
    required String? newRfid,
  });

  /// Rows ready for the next worker pass (status='queued' AND nextAttemptAt<=now).
  Future<List<CardOutboxData>> dueCardOutboxRows({required int nowSec, int limit = 20});

  /// Has the worker got a queued row for this user? Snapshot sync uses this
  /// to avoid stomping an in-flight optimistic edit with BE truth.
  Future<bool> hasQueuedCardWrite(String userId);

  Future<void> markCardOutboxDone(String id);

  /// Terminal failure — local Students row should already be reverted by caller.
  Future<void> markCardOutboxDead(String id, String error);

  /// Transient failure — backoff and try again.
  Future<void> bumpCardOutboxRetry({
    required String id,
    required int attempts,
    required int nextAttemptAt,
    required String error,
  });
}

abstract class SyncStorePort {
  Future<List<TapRecord>> getUnpublishedRecords();
  Future<Student?> getStudentByUserId(String userId);
  Future<Student?> getStudentByCard(String rfidNumber);
  Future<void> markPublished(String recordId, int publishedAt);
}

class StudentSnapshotSyncResult {
  final List<String> removedUserIds;
  final List<String> removedCardNos;
  // Cards that were cleared from existing students (rfid_number set to null on server)
  final List<String> revokedCardNos;

  const StudentSnapshotSyncResult({
    this.removedUserIds = const [],
    this.removedCardNos = const [],
    this.revokedCardNos = const [],
  });
}

@DriftDatabase(tables: [Students, TapRecords, CardOutbox, HikOutbox])
class AppDatabase extends _$AppDatabase
    implements
        StudentStorePort,
        AttendanceStorePort,
        SyncStorePort,
        AbsensiInvalidatorPort,
        StudentDeletionPort,
        CardOutboxPort,
        HikOutboxPort {
  AppDatabase._() : super(_openConnection());

  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await m.deleteTable('students');
            await m.createTable(students);
          }
          if (from < 4) {
            // Reset legacy history rows that were tied to mutable card ownership.
            await delete(tapRecords).go();
          }
          if (from < 5) {
            await m.addColumn(students, students.noTelpWali);
          }
          if (from < 6) {
            // Rename `nis` → `nisn` to match BE canonical naming.
            // Simplest path: wipe and let the next snapshot resync repopulate.
            await m.deleteTable('students');
            await m.createTable(students);
          }
          if (from < 7) {
            // Card outbox + sync status. Wipe students so the new column gets
            // its default; next snapshot resync repopulates.
            await m.deleteTable('students');
            await m.createTable(students);
            await m.createTable(cardOutbox);
          }
          if (from < 8) {
            // Legacy tap_records tables were created before `rfid_number`
            // existed as a column. Drop + recreate at current schema.
            await m.deleteTable('tap_records');
            await m.createTable(tapRecords);
          }
          if (from < 9) {
            await m.createTable(hikOutbox);
          }
        },
      );

  // ── Students ──────────────────────────────────────────────────────────

  @override
  Future<List<Student>> getAllStudents() => select(students).get();

  @override
  Future<int> getStudentCount() async {
    final count = countAll();
    final query = selectOnly(students)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count)!;
  }

  @override
  Future<Student?> getStudentByCard(String rfidNumber) => (select(students)
        ..where((s) => s.rfidNumber.equals(rfidNumber)))
      .getSingleOrNull();

  @override
  Future<Student?> getStudentByUserId(String userId) => (select(students)
        ..where((s) => s.userId.equals(userId)))
      .getSingleOrNull();

  @override
  Future<Student?> getStudentByNisn(String nisn) => (select(students)
        ..where((s) => s.nisn.equals(nisn)))
      .getSingleOrNull();

  @override
  Future<void> upsertStudents(List<StudentsCompanion> rows) async {
    await batch((b) {
      for (final row in rows) {
        b.insert(
          students,
          row,
          onConflict: DoUpdate(
            (old) => StudentsCompanion(
              nama: row.nama,
              nisn: row.nisn,
              kelas: row.kelas,
              // rfid_number is now server-authoritative
              rfidNumber: row.rfidNumber,
              noTelpWali: row.noTelpWali,
              syncedAt: row.syncedAt,
            ),
            target: [students.userId],
          ),
        );
      }
    });
  }

  /// Mirror students table to match server snapshot exactly.
  /// rfid_number is now server-authoritative: synced from server, resets hikRegistered on change.
  @override
  Future<StudentSnapshotSyncResult> syncStudentsSnapshot({
    required List<StudentsCompanion> rows,
    required Set<String> serverUserIds,
    Set<String> protectedUserIds = const {},
  }) async {
    final beforeRows = await getAllStudents();
    final beforeByUserId = <String, Student>{
      for (final s in beforeRows) s.userId: s,
    };

    // Pull the set of users whose card edits are currently mid-flight in the
    // local outbox. Snapshot must NOT stomp their rfid_number — the worker
    // will reconcile after BE acks (success → BE returns the new value next
    // pull, failure → worker reverts).
    final inFlightUserIds = await _queuedCardUserIds();

    // Detect card changes before upsert. Skip flagging hikRegistered for
    // in-flight users so the snapshot doesn't double-trigger work.
    final cardChangedUserIds = <String>[];
    final revokedCardNos = <String>[];
    for (final row in rows) {
      final userId = row.userId.value;
      if (inFlightUserIds.contains(userId)) continue;
      final newCard = row.rfidNumber.present ? row.rfidNumber.value : null;
      final old = beforeByUserId[userId];
      if (old != null && old.rfidNumber != newCard) {
        cardChangedUserIds.add(userId);
        if (old.rfidNumber != null && old.rfidNumber!.isNotEmpty) {
          revokedCardNos.add(old.rfidNumber!);
        }
      }
    }

    // Filter snapshot rows: in-flight users keep their local optimistic state.
    final applicableRows = inFlightUserIds.isEmpty
        ? rows
        : rows.where((r) => !inFlightUserIds.contains(r.userId.value)).toList();

    await transaction(() async {
      if (applicableRows.isNotEmpty) {
        await upsertStudents(applicableRows);
      }

      // Reset hikRegistered for students with changed card → triggers re-push
      if (cardChangedUserIds.isNotEmpty) {
        await (update(students)
              ..where((s) => s.userId.isIn(cardChangedUserIds)))
            .write(const StudentsCompanion(hikRegistered: Value(false)));
      }

      final retainedUserIds = <String>{...serverUserIds, ...protectedUserIds};

      if (retainedUserIds.isEmpty) {
        await delete(students).go();
        await delete(tapRecords).go();
        return;
      }

      await (delete(students)
            ..where((s) => s.userId.isNotIn(retainedUserIds.toList())))
          .go();

      final activeStudents = await getAllStudents();
      final activeCards = activeStudents
          .map((s) => s.rfidNumber)
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();

      if (activeCards.isEmpty) {
        await delete(tapRecords).go();
      } else {
        await (delete(tapRecords)
              ..where((r) => r.rfidNumber.isNotIn(activeCards)))
            .go();
      }
    });

    final removedUserIds = beforeByUserId.keys
        .where((id) => !serverUserIds.contains(id) && !protectedUserIds.contains(id))
        .toList();
    final removedCardNos = removedUserIds
        .map((id) => beforeByUserId[id]?.rfidNumber)
        .whereType<String>()
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    // Side-effect: tell sijinak's HikSyncWorker about every divergence the
    // snapshot just resolved. BE is the source of truth; Hik is downstream.
    await _enqueueHikSnapshotDiffs(
      cardChanged: cardChangedUserIds,
      removedUserIds: removedUserIds,
      beforeByUserId: beforeByUserId,
      rowsByUserId: {for (final r in rows) r.userId.value: r},
    );

    return StudentSnapshotSyncResult(
      removedUserIds: removedUserIds,
      removedCardNos: removedCardNos,
      revokedCardNos: revokedCardNos,
    );
  }

  @override
  Future<List<Student>> getUnregisteredStudents() =>
      (select(students)..where((s) => s.hikRegistered.equals(false))).get();

  @override
  Future<void> markHikRegistered(String userId) =>
      (update(students)..where((s) => s.userId.equals(userId))).write(
        const StudentsCompanion(hikRegistered: Value(true)),
      );

  @override
  Future<void> assignCardToStudent(String userId, String rfidNumber) =>
      (update(students)..where((s) => s.userId.equals(userId))).write(
        StudentsCompanion(rfidNumber: Value(rfidNumber)),
      );

  @override
  Future<void> removeCardFromStudent(String userId) =>
      (update(students)..where((s) => s.userId.equals(userId))).write(
        const StudentsCompanion(rfidNumber: Value(null)),
      );

  // ── Tap Records ───────────────────────────────────────────────────────

  Future<int> insertTapRecord(TapRecordsCompanion record) =>
      into(tapRecords).insert(record, mode: InsertMode.insertOrIgnore);

  @override
  Future<List<TapRecord>> getUnpublishedRecords() =>
      (select(tapRecords)..where((r) => r.publishedAt.isNull())).get();

  Stream<List<TapRecord>> watchUnpublishedRecords() =>
      (select(tapRecords)..where((r) => r.publishedAt.isNull())).watch();

  Future<int> getUnpublishedCount() async {
    final count = countAll();
    final query = selectOnly(tapRecords)
      ..addColumns([count])
      ..where(tapRecords.publishedAt.isNull());
    final row = await query.getSingle();
    return row.read(count)!;
  }

  @override
  Future<List<TapRecord>> getTodayRecordsForCard(String rfidNumber) {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
    final endOfDay = startOfDay + 86400;
    return (select(tapRecords)
          ..where(
            (r) =>
                r.rfidNumber.equals(rfidNumber) &
                r.deviceTime.isBiggerOrEqualValue(startOfDay) &
                r.deviceTime.isSmallerThanValue(endOfDay),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.deviceTime)]))
        .get();
  }

  @override
  Future<List<TapRecord>> getTodayRecordsForStudent(String userId) {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 1000;
    final endOfDay = startOfDay + 86400;
    return (select(tapRecords)
          ..where(
            (r) =>
                r.id.like('${userId}_%') &
                r.deviceTime.isBiggerOrEqualValue(startOfDay) &
                r.deviceTime.isSmallerThanValue(endOfDay),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.deviceTime)]))
        .get();
  }

  @override
  Future<void> markPublished(String recordId, int publishedAt) =>
      (update(tapRecords)..where((r) => r.id.equals(recordId))).write(
        TapRecordsCompanion(publishedAt: Value(publishedAt)),
      );

  @override
  Future<void> forgetStudent(String userId) async {
    await transaction(() async {
      await (delete(tapRecords)
            ..where((r) => r.id.like('${userId}_%') & r.publishedAt.isNull()))
          .go();
      // Discard any pending sijinak→BE card writes — student no longer exists.
      await (delete(cardOutbox)..where((c) => c.userId.equals(userId))).go();
      // Discard any pending Hik upsert/delete-card ops — they'll be replaced
      // by a fresh deletePerson below.
      await (delete(hikOutbox)..where((h) => h.userId.equals(userId))).go();
      await (delete(students)..where((s) => s.userId.equals(userId))).go();
    });
  }

  // ── Card Outbox ────────────────────────────────────────────────────────

  @override
  Future<String> enqueueCardWrite({
    required String userId,
    required String? oldRfid,
    required String? newRfid,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await into(cardOutbox).insert(
      CardOutboxCompanion(
        id: Value(id),
        userId: Value(userId),
        oldRfid: Value(oldRfid),
        newRfid: Value(newRfid),
        status: const Value('queued'),
        attempts: const Value(0),
        nextAttemptAt: Value(now),
        createdAt: Value(now),
      ),
    );
    return id;
  }

  @override
  Future<List<CardOutboxData>> dueCardOutboxRows({
    required int nowSec,
    int limit = 20,
  }) {
    return (select(cardOutbox)
          ..where((c) =>
              c.status.equals('queued') &
              c.nextAttemptAt.isSmallerOrEqualValue(nowSec))
          ..orderBy([(c) => OrderingTerm.asc(c.createdAt)])
          ..limit(limit))
        .get();
  }

  @override
  Future<bool> hasQueuedCardWrite(String userId) async {
    final query = selectOnly(cardOutbox)
      ..addColumns([cardOutbox.id])
      ..where(cardOutbox.userId.equals(userId) & cardOutbox.status.equals('queued'))
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> markCardOutboxDone(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(cardOutbox)..where((c) => c.id.equals(id))).write(
      CardOutboxCompanion(
        status: const Value('done'),
        completedAt: Value(now),
        lastError: const Value(null),
      ),
    );
  }

  @override
  Future<void> markCardOutboxDead(String id, String error) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(cardOutbox)..where((c) => c.id.equals(id))).write(
      CardOutboxCompanion(
        status: const Value('dead'),
        completedAt: Value(now),
        lastError: Value(error),
      ),
    );
  }

  @override
  Future<void> bumpCardOutboxRetry({
    required String id,
    required int attempts,
    required int nextAttemptAt,
    required String error,
  }) async {
    await (update(cardOutbox)..where((c) => c.id.equals(id))).write(
      CardOutboxCompanion(
        attempts: Value(attempts),
        nextAttemptAt: Value(nextAttemptAt),
        lastError: Value(error),
      ),
    );
  }

  @override
  Future<void> setStudentCardSyncStatus(String userId, String status) {
    return (update(students)..where((s) => s.userId.equals(userId))).write(
      StudentsCompanion(cardSyncStatus: Value(status)),
    );
  }

  /// Used by the worker when BE rejects (4xx) or retries exhaust — restores
  /// the local Students row to the snapshot taken at enqueue time.
  Future<void> revertStudentCard(String userId, String? oldRfid) async {
    await (update(students)..where((s) => s.userId.equals(userId))).write(
      StudentsCompanion(
        rfidNumber: Value(oldRfid),
        cardSyncStatus: const Value('failed'),
      ),
    );
  }

  /// Reset the most-recent dead CardOutbox row for [userId] back to queued
  /// so the worker retries. Also restores Students.rfidNumber to the intended
  /// newRfid (the revert path had set it back to oldRfid) and resets
  /// cardSyncStatus to 'pending' so the UI reflects the in-flight state.
  Future<void> requeueDeadCardOutbox(String userId) async {
    final deadRows = await (select(cardOutbox)
          ..where((r) => r.userId.equals(userId) & r.status.equals('dead'))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
          ..limit(1))
        .get();
    if (deadRows.isEmpty) return;
    final row = deadRows.first;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(cardOutbox)..where((r) => r.id.equals(row.id))).write(
      CardOutboxCompanion(
        status: const Value('queued'),
        attempts: const Value(0),
        nextAttemptAt: Value(nowSec),
        lastError: const Value(null),
      ),
    );
    await revertStudentCard(userId, row.newRfid);
    await setStudentCardSyncStatus(userId, 'pending');
  }

  /// Accelerate all queued HikOutbox rows for [userId] — set nextAttemptAt=now
  /// so the next worker tick picks them up without waiting out the backoff.
  Future<void> accelerateHikOutbox(String userId) async {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(hikOutbox)
          ..where((r) => r.userId.equals(userId) & r.status.equals('queued')))
        .write(HikOutboxCompanion(nextAttemptAt: Value(nowSec)));
  }

  /// Requeue ALL dead CardOutbox rows across all users. For each affected user,
  /// also restores Students.rfidNumber to the intended newRfid and resets
  /// cardSyncStatus to 'pending'. Returns count of affected users.
  Future<int> requeueAllDeadCardOutbox() async {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final deadRows = await (select(cardOutbox)
          ..where((r) => r.status.equals('dead'))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
    if (deadRows.isEmpty) return 0;
    final latestByUser = _latestDeadRowByUser(deadRows);
    await transaction(() async {
      await (update(cardOutbox)..where((r) => r.status.equals('dead'))).write(
        CardOutboxCompanion(
          status: const Value('queued'),
          attempts: const Value(0),
          nextAttemptAt: Value(nowSec),
          lastError: const Value(null),
        ),
      );
      for (final entry in latestByUser.entries) {
        await revertStudentCard(entry.key, entry.value.newRfid);
        await setStudentCardSyncStatus(entry.key, 'pending');
      }
    });
    return latestByUser.length;
  }

  Map<String, CardOutboxData> _latestDeadRowByUser(List<CardOutboxData> rows) {
    final result = <String, CardOutboxData>{};
    for (final row in rows) {
      result.putIfAbsent(row.userId, () => row);
    }
    return result;
  }

  /// Accelerate ALL queued HikOutbox rows — set nextAttemptAt=now globally.
  Future<void> accelerateAllHikOutbox() async {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(hikOutbox)..where((r) => r.status.equals('queued')))
        .write(HikOutboxCompanion(nextAttemptAt: Value(nowSec)));
  }

  // ── Hik Outbox ────────────────────────────────────────────────────────

  @override
  Future<String?> enqueueHikWrite({
    required String userId,
    required String employeeNo,
    required String operation,
    String? name,
    String? oldRfid,
    String? newRfid,
  }) async {
    if (!_shouldEnqueueHikOp(operation, oldRfid, newRfid)) return null;

    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await into(hikOutbox).insert(
      HikOutboxCompanion(
        id: Value(id),
        userId: Value(userId),
        employeeNo: Value(employeeNo),
        name: Value(name),
        oldRfid: Value(oldRfid),
        newRfid: Value(newRfid),
        operation: Value(operation),
        status: const Value('queued'),
        attempts: const Value(0),
        nextAttemptAt: Value(now),
        createdAt: Value(now),
      ),
    );
    return id;
  }

  /// Filter out enqueues that would have no effect on the device.
  bool _shouldEnqueueHikOp(String operation, String? oldRfid, String? newRfid) {
    switch (operation) {
      case HikOpType.upsertCard:
        // Nothing to push if there's no card. Avoid registering a person on
        // Hik that will never tap anything.
        return newRfid != null && newRfid.isNotEmpty;
      case HikOpType.deleteCard:
        // Nothing to delete if there was no card on the device anyway.
        return oldRfid != null && oldRfid.isNotEmpty;
      case HikOpType.deletePerson:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<List<HikOutboxData>> dueHikOutboxRows({
    required int nowSec,
    int limit = 20,
  }) {
    return (select(hikOutbox)
          ..where((h) =>
              h.status.equals('queued') &
              h.nextAttemptAt.isSmallerOrEqualValue(nowSec))
          ..orderBy([(h) => OrderingTerm.asc(h.createdAt)])
          ..limit(limit))
        .get();
  }

  @override
  Future<void> markHikOutboxDone(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await (update(hikOutbox)..where((h) => h.id.equals(id))).write(
      HikOutboxCompanion(
        status: const Value('done'),
        completedAt: Value(now),
        lastError: const Value(null),
      ),
    );
  }

  @override
  Future<void> bumpHikOutboxRetry({
    required String id,
    required int attempts,
    required int nextAttemptAt,
    required String error,
  }) async {
    await (update(hikOutbox)..where((h) => h.id.equals(id))).write(
      HikOutboxCompanion(
        attempts: Value(attempts),
        nextAttemptAt: Value(nextAttemptAt),
        lastError: Value(error),
      ),
    );
  }

  Future<void> _enqueueHikSnapshotDiffs({
    required List<String> cardChanged,
    required List<String> removedUserIds,
    required Map<String, Student> beforeByUserId,
    required Map<String, StudentsCompanion> rowsByUserId,
  }) async {
    for (final userId in cardChanged) {
      await _enqueueHikDiffForCardChange(userId, beforeByUserId, rowsByUserId);
    }
    for (final userId in removedUserIds) {
      await enqueueHikWrite(
        userId: userId,
        employeeNo: hikvisionEmployeeNoFor(userId),
        operation: HikOpType.deletePerson,
      );
    }
  }

  Future<void> _enqueueHikDiffForCardChange(
    String userId,
    Map<String, Student> beforeByUserId,
    Map<String, StudentsCompanion> rowsByUserId,
  ) async {
    final row = rowsByUserId[userId];
    if (row == null) return;
    final before = beforeByUserId[userId];
    final newRfid = row.rfidNumber.present ? row.rfidNumber.value : null;
    final oldRfid = before?.rfidNumber;
    final hasNew = newRfid != null && newRfid.isNotEmpty;
    final operation = hasNew ? HikOpType.upsertCard : HikOpType.deleteCard;
    await enqueueHikWrite(
      userId: userId,
      employeeNo: hikvisionEmployeeNoFor(userId),
      operation: operation,
      name: row.nama.present ? row.nama.value : before?.nama,
      oldRfid: oldRfid,
      newRfid: newRfid,
    );
  }

  Future<Set<String>> _queuedCardUserIds() async {
    final query = selectOnly(cardOutbox, distinct: true)
      ..addColumns([cardOutbox.userId])
      ..where(cardOutbox.status.equals('queued'));
    final rows = await query.get();
    return rows.map((r) => r.read(cardOutbox.userId)!).toSet();
  }

  @override
  Future<int> dropTapRecordsForUserOnDate(String userId, DateTime date) {
    final startOfDay =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/ 1000;
    final endOfDay = startOfDay + 86400;
    return (delete(tapRecords)
          ..where(
            (r) =>
                r.id.like('${userId}_%') &
                r.deviceTime.isBiggerOrEqualValue(startOfDay) &
                r.deviceTime.isSmallerThanValue(endOfDay),
          ))
        .go();
  }

  Future<List<TapRecord>> getRecentRecords({int limit = 50}) =>
      (select(tapRecords)
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
            ..limit(limit))
          .get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'sijinak.db'));
    return NativeDatabase.createInBackground(file);
  });
}
