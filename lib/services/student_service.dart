import '../config/app_config.dart';
import '../data/local/database.dart';
import '../data/hikvision/isapi_client.dart';
import '../data/remote/api_client.dart';

/// Per-row progress for bulk CSV/XLSX card assignment.
class BulkCardAssignProgress {
  final int current;
  final int total;
  final String currentNisn;
  final int success;
  final int skipped;
  final int failed;
  final bool done;
  final List<String> errors;

  const BulkCardAssignProgress({
    required this.current,
    required this.total,
    required this.currentNisn,
    required this.success,
    required this.skipped,
    required this.failed,
    required this.done,
    this.errors = const [],
  });
}

class HikvisionCleanupResult {
  final int usersDeleted;
  final int cardsDeleted;
  final int usersSkippedAdmin;
  final List<String> deletedUsers;
  final List<String> deletedCards;

  const HikvisionCleanupResult({
    this.usersDeleted = 0,
    this.cardsDeleted = 0,
    this.usersSkippedAdmin = 0,
    this.deletedUsers = const [],
    this.deletedCards = const [],
  });
}

/// Pure read-side + bulk-import facade. Card mutations are enqueued via
/// [AppDatabase.enqueueCardChange], which fans out to the CardOutbox (server)
/// and HikOutbox (device) workers; this class never talks to the device or BE
/// for single-card edits.
class StudentService {
  final StudentStorePort db;
  final HikvisionDevicePort Function(AppConfig config) _hikvisionClientFactory;

  StudentService(
    this.db, {
    HikvisionDevicePort Function(AppConfig config)? hikvisionClientFactory,
  }) : _hikvisionClientFactory = hikvisionClientFactory ??
            ((config) => IsapiClient(
                  baseUrl: config.hikvisionBaseUrl,
                  username: config.hikvisionUser,
                  password: config.hikvisionPassword,
                ));

  Future<List<Student>> loadStudents() => db.getAllStudents();

  /// Direct, synchronous push of one card change to the Hikvision device.
  /// Hikvision lives on the LAN, so this works even when the internet/BE is
  /// down. Returns on success; THROWS on device failure so the caller can fall
  /// back to the HikOutbox retry queue. Mirrors the old (proven) assignCard.
  Future<void> pushCardToDevice({
    required Student student,
    required String? newRfid,
    required AppConfig config,
  }) async {
    final client = _hikvisionClientFactory(config);
    final hasNew = newRfid != null && newRfid.isNotEmpty;
    if (!hasNew) {
      await _pushDeviceRemoval(client, student);
      return;
    }
    await client.upsertPerson(employeeNo: student.userId, name: student.nama);
    final old = student.rfidNumber;
    if (old != null && old.isNotEmpty && old != newRfid) {
      await _bestEffortDeleteCard(client, old);
    }
    await client.upsertCard(rfidNumber: newRfid, employeeNo: student.userId);

    // Read-back: confirm the card actually landed (Hikvision can 200 yet not
    // persist). Throw on miss so the caller falls back to the retry queue.
    final stored = await client.deviceHasCard(rfidNumber: newRfid);
    if (!stored) {
      throw const HikCardNotConfirmedException();
    }
  }

  Future<void> _pushDeviceRemoval(
    HikvisionDevicePort client,
    Student student,
  ) async {
    final old = student.rfidNumber;
    if (old != null && old.isNotEmpty) {
      await _bestEffortDeleteCard(client, old);
    }
    await client.deletePerson(employeeNo: student.userId);
  }

  Future<void> _bestEffortDeleteCard(
    HikvisionDevicePort client,
    String rfid,
  ) async {
    try {
      await client.deleteCard(rfidNumber: rfid);
    } catch (_) {
      // Old card may already be gone on the device; don't fail the whole op.
    }
  }

  /// Bulk CSV/XLSX import: per row, optimistically update Drift + enqueue a
  /// CardOutbox row. The background worker drains the queue against BE.
  /// HTTP is NOT fired here, so the dialog finishes fast and the BE doesn't
  /// receive a burst of N parallel calls. Status per row is visible in the
  /// student-table badge column.
  Stream<BulkCardAssignProgress> bulkAssignCards({
    required List<Map<String, String>> rows,
    required BackendApiPort api,
  }) async* {
    int success = 0;
    int skipped = 0;
    int failed = 0;
    final errors = <String>[];

    for (int i = 0; i < rows.length; i++) {
      final nisn = rows[i]['nisn'] ?? '';
      final rfidNumber = rows[i]['rfidNumber'] ?? '';

      yield _progress(i + 1, rows.length, nisn, success, skipped, failed, false, const []);

      final outcome = await _enqueueOneFromCsv(nisn, rfidNumber);
      success += outcome.successDelta;
      skipped += outcome.skippedDelta;
      failed += outcome.failedDelta;
      if (outcome.error != null) errors.add(outcome.error!);
    }

    yield _progress(rows.length, rows.length, '', success, skipped, failed, true, errors);
  }

  Future<_BulkAssignOutcome> _enqueueOneFromCsv(
    String nisn,
    String rfidNumber,
  ) async {
    if (nisn.isEmpty || rfidNumber.isEmpty) {
      return const _BulkAssignOutcome(skippedDelta: 1);
    }

    final student = await db.getStudentByNisn(nisn);
    if (student == null) {
      return _BulkAssignOutcome(
        skippedDelta: 1,
        error: 'NISN $nisn: siswa belum ada di local DB, sinkronkan siswa dulu',
      );
    }
    if (student.rfidNumber == rfidNumber) {
      return const _BulkAssignOutcome(skippedDelta: 1);
    }
    if (student.rfidNumber != null) {
      return _BulkAssignOutcome(
        skippedDelta: 1,
        error: 'NISN $nisn: sudah punya kartu (${student.rfidNumber})',
      );
    }

    try {
      await db.enqueueCardChange(
        userId: student.userId,
        oldRfid: student.rfidNumber,
        newRfid: rfidNumber,
      );
      await db.assignCardToStudent(student.userId, rfidNumber);
      return const _BulkAssignOutcome(successDelta: 1);
    } catch (e) {
      return _BulkAssignOutcome(failedDelta: 1, error: 'NISN $nisn: $e');
    }
  }

  BulkCardAssignProgress _progress(
    int current,
    int total,
    String nisn,
    int success,
    int skipped,
    int failed,
    bool done,
    List<String> errors,
  ) {
    return BulkCardAssignProgress(
      current: current,
      total: total,
      currentNisn: nisn,
      success: success,
      skipped: skipped,
      failed: failed,
      done: done,
      errors: errors,
    );
  }

  /// Full reconciliation by scanning device data and deleting stale entries
  /// that are not present in local DB. Hikvision admin entries are skipped.
  ///
  /// This still runs locally because it requires walking the device's full
  /// person/card lists — BE never sees this data. It only deletes; it never
  /// adds (adds come from BE via the outbox).
  Future<HikvisionCleanupResult> cleanupStaleFromHikvision({
    required AppConfig config,
  }) async {
    if (!config.isHikvisionConfigured) return const HikvisionCleanupResult();

    final localStudents = await db.getAllStudents();
    final localEmployeeNos = localStudents
        .map((s) => hikvisionEmployeeNoFor(s.userId))
        .where((id) => id.isNotEmpty)
        .toSet();
    final localCardNos = localStudents
        .map((s) => s.rfidNumber)
        .whereType<String>()
        .where((card) => card.isNotEmpty)
        .toSet();

    final client = _hikvisionClientFactory(config);
    final deviceUsers = await client.listUsers();
    final deviceCards = await client.listCards();

    final adminEmployeeNos = <String>{};
    int usersDeleted = 0;
    int usersSkippedAdmin = 0;
    final deletedUsers = <String>[];

    for (final user in deviceUsers) {
      final outcome = await _cleanupUser(client, user, localEmployeeNos, adminEmployeeNos);
      usersDeleted += outcome.deletedDelta;
      usersSkippedAdmin += outcome.skippedAdminDelta;
      if (outcome.deletedId != null) deletedUsers.add(outcome.deletedId!);
    }

    int cardsDeleted = 0;
    final deletedCards = <String>[];
    for (final card in deviceCards) {
      final outcome = await _cleanupCard(client, card, localCardNos, adminEmployeeNos);
      cardsDeleted += outcome.deletedDelta;
      if (outcome.deletedId != null) deletedCards.add(outcome.deletedId!);
    }

    return HikvisionCleanupResult(
      usersDeleted: usersDeleted,
      cardsDeleted: cardsDeleted,
      usersSkippedAdmin: usersSkippedAdmin,
      deletedUsers: deletedUsers,
      deletedCards: deletedCards,
    );
  }

  Future<_CleanupOutcome> _cleanupUser(
    HikvisionDevicePort client,
    HikvisionUserInfo user,
    Set<String> localEmployeeNos,
    Set<String> adminEmployeeNos,
  ) async {
    final employeeNo = user.employeeNo.trim();
    if (employeeNo.isEmpty) return const _CleanupOutcome();

    final userType = (user.userType ?? '').trim().toLowerCase();
    if (userType == 'administrator') {
      adminEmployeeNos.add(employeeNo);
      return const _CleanupOutcome(skippedAdminDelta: 1);
    }

    if (localEmployeeNos.contains(employeeNo)) return const _CleanupOutcome();

    try {
      await client.deletePerson(employeeNo: employeeNo);
      return _CleanupOutcome(deletedDelta: 1, deletedId: employeeNo);
    } catch (_) {
      return const _CleanupOutcome();
    }
  }

  Future<_CleanupOutcome> _cleanupCard(
    HikvisionDevicePort client,
    HikvisionCardInfo card,
    Set<String> localCardNos,
    Set<String> adminEmployeeNos,
  ) async {
    final rfidNumber = card.rfidNumber.trim();
    if (rfidNumber.isEmpty) return const _CleanupOutcome();

    final ownerEmployeeNo = (card.employeeNo ?? '').trim();
    if (ownerEmployeeNo.isNotEmpty && adminEmployeeNos.contains(ownerEmployeeNo)) {
      return const _CleanupOutcome();
    }
    if (localCardNos.contains(rfidNumber)) return const _CleanupOutcome();

    try {
      await client.deleteCard(rfidNumber: rfidNumber);
      return _CleanupOutcome(deletedDelta: 1, deletedId: rfidNumber);
    } catch (_) {
      return const _CleanupOutcome();
    }
  }
}

/// Thrown by [StudentService.pushCardToDevice] when the post-write read-back
/// can't find the card on the device — the write didn't stick. Signals the
/// caller to queue a retry rather than report success.
class HikCardNotConfirmedException implements Exception {
  const HikCardNotConfirmedException();

  @override
  String toString() =>
      'HikCardNotConfirmedException: kartu tidak terkonfirmasi di device';
}

class _BulkAssignOutcome {
  final int successDelta;
  final int skippedDelta;
  final int failedDelta;
  final String? error;

  const _BulkAssignOutcome({
    this.successDelta = 0,
    this.skippedDelta = 0,
    this.failedDelta = 0,
    this.error,
  });
}

class _CleanupOutcome {
  final int deletedDelta;
  final int skippedAdminDelta;
  final String? deletedId;

  const _CleanupOutcome({
    this.deletedDelta = 0,
    this.skippedAdminDelta = 0,
    this.deletedId,
  });
}
