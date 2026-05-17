import '../config/app_config.dart';
import '../data/local/database.dart';
import '../data/hikvision/isapi_client.dart';
import '../data/remote/api_client.dart';
import 'pending_card_cache_service.dart';

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

/// Pure read-side + bulk-import facade. All single-card mutations now go
/// through the BE unified endpoint (`POST /api/desktop/students/{uid}/card`),
/// with the Hikvision push handled asynchronously by the DeviceJob worker.
class StudentService {
  final StudentStorePort db;
  final HikvisionDevicePort Function(AppConfig config) _hikvisionClientFactory;
  final PendingCardCachePort _pendingCardCache;

  StudentService(
    this.db, {
    HikvisionDevicePort Function(AppConfig config)? hikvisionClientFactory,
    PendingCardCachePort? pendingCardCache,
  })  : _hikvisionClientFactory = hikvisionClientFactory ??
            ((config) => IsapiClient(
                  baseUrl: config.hikvisionBaseUrl,
                  username: config.hikvisionUser,
                  password: config.hikvisionPassword,
                )),
        _pendingCardCache = pendingCardCache ?? PendingCardCacheService();

  Future<List<Student>> loadStudents() => db.getAllStudents();

  Future<List<Student>> getUnregistered() => db.getUnregisteredStudents();

  /// Drain rows where the NIS was previously unknown locally but a card was
  /// reserved. When the student appears in the next snapshot, push the card
  /// through the unified BE endpoint (which queues the Hikvision sync job).
  Future<int> applyPendingCardAssignments(BackendApiPort api) async {
    final pending = await _pendingCardCache.listAll();
    if (pending.isEmpty) return 0;

    int applied = 0;
    for (final row in pending) {
      final ok = await _applySinglePending(api, row);
      if (ok) applied++;
    }
    return applied;
  }

  Future<bool> _applySinglePending(BackendApiPort api, PendingCardAssignment row) async {
    try {
      final student = await db.getStudentByNisn(row.nisn);
      if (student == null) return false;
      if (student.rfidNumber == row.rfidNumber) {
        await _pendingCardCache.remove(row.nisn);
        return false;
      }
      await api.setStudentCard(student.userId, row.rfidNumber);
      await _pendingCardCache.remove(row.nisn);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Bulk assign from CSV/XLSX. Each row writes through the BE unified
  /// `setStudentCard` endpoint; the DeviceJob worker handles Hikvision.
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

      final outcome = await _assignOneFromCsv(api, nisn, rfidNumber);
      success += outcome.successDelta;
      skipped += outcome.skippedDelta;
      failed += outcome.failedDelta;
      if (outcome.error != null) errors.add(outcome.error!);
    }

    yield _progress(rows.length, rows.length, '', success, skipped, failed, true, errors);
  }

  Future<_BulkAssignOutcome> _assignOneFromCsv(
    BackendApiPort api,
    String nisn,
    String rfidNumber,
  ) async {
    if (nisn.isEmpty || rfidNumber.isEmpty) {
      return const _BulkAssignOutcome(skippedDelta: 1);
    }

    final student = await db.getStudentByNisn(nisn);
    if (student == null) {
      await _pendingCardCache.upsert(nisn, rfidNumber);
      return _BulkAssignOutcome(
        skippedDelta: 1,
        error: 'NISN $nisn: siswa belum ada di local DB, disimpan ke cache',
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
      await api.setStudentCard(student.userId, rfidNumber);
      await db.assignCardToStudent(student.userId, rfidNumber);
      return const _BulkAssignOutcome(successDelta: 1);
    } on ApiException catch (e) {
      return _BulkAssignOutcome(failedDelta: 1, error: 'NISN $nisn: ${e.message}');
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
        .map((s) => s.userId.replaceAll('-', ''))
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
