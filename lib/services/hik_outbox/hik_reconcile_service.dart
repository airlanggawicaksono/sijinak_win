import '../../data/hikvision/isapi_client.dart';
import '../../data/local/database.dart';

/// One side of the diff. Each entry maps to exactly one HikOutbox row that
/// will be enqueued when the operator confirms the reconcile preview.
class HikReconcilePlanEntry {
  final String operation; // HikOpType.upsertCard | deleteCard | deletePerson
  final String userId; // hex employee_no derived if "orphan" (no local row)
  final String employeeNo;
  final String? name;
  final String? oldRfid;
  final String? newRfid;
  final String reason; // human-readable: "card mismatch", "orphan person", etc

  const HikReconcilePlanEntry({
    required this.operation,
    required this.userId,
    required this.employeeNo,
    required this.reason,
    this.name,
    this.oldRfid,
    this.newRfid,
  });
}

/// Summary surfaced to the UI preview dialog.
class HikReconcilePlan {
  final List<HikReconcilePlanEntry> upserts;
  final List<HikReconcilePlanEntry> personDeletes;
  final List<HikReconcilePlanEntry> cardDeletes;
  final int adminsSkipped;

  const HikReconcilePlan({
    required this.upserts,
    required this.personDeletes,
    required this.cardDeletes,
    required this.adminsSkipped,
  });

  int get total => upserts.length + personDeletes.length + cardDeletes.length;
  bool get isEmpty => total == 0;
}

/// Pulls device truth, compares to local Drift, builds a HikOutbox plan.
/// Local DB is the source of truth (it mirrors BE); device is the downstream
/// sink. We never write from device back into local.
class HikReconcileService {
  final AppDatabase db;
  final HikvisionDevicePort hik;

  HikReconcileService({required this.db, required this.hik});

  /// Step 1 of the flow — pure read, no enqueues. UI shows the result so the
  /// operator can review before committing.
  Future<HikReconcilePlan> buildPlan() async {
    final students = await db.getAllStudents();
    final deviceUsers = await hik.listUsers();
    final deviceCards = await hik.listCards();

    final localByEmployeeNo = <String, Student>{
      for (final s in students) hikvisionEmployeeNoFor(s.userId): s,
    };

    final adminEmployeeNos = _collectAdminEmployeeNos(deviceUsers);
    final deviceUsersByEmployeeNo = <String, HikvisionUserInfo>{
      for (final u in deviceUsers) u.employeeNo.trim(): u,
    };

    final upserts = _planUpserts(students, deviceUsersByEmployeeNo, deviceCards);
    final personDeletes = _planPersonDeletes(
      deviceUsers, localByEmployeeNo, adminEmployeeNos,
    );
    final cardDeletes = _planOrphanCardDeletes(
      deviceCards, localByEmployeeNo, adminEmployeeNos,
    );

    return HikReconcilePlan(
      upserts: upserts,
      personDeletes: personDeletes,
      cardDeletes: cardDeletes,
      adminsSkipped: adminEmployeeNos.length,
    );
  }

  /// Step 2 — operator confirmed the preview. Enqueue every entry.
  Future<int> enqueuePlan(HikReconcilePlan plan) async {
    int enqueued = 0;
    for (final entry in plan.upserts) {
      final id = await _enqueue(entry);
      if (id != null) enqueued++;
    }
    for (final entry in plan.personDeletes) {
      final id = await _enqueue(entry);
      if (id != null) enqueued++;
    }
    for (final entry in plan.cardDeletes) {
      final id = await _enqueue(entry);
      if (id != null) enqueued++;
    }
    return enqueued;
  }

  Future<String?> _enqueue(HikReconcilePlanEntry e) {
    return db.enqueueHikWrite(
      userId: e.userId,
      employeeNo: e.employeeNo,
      operation: e.operation,
      name: e.name,
      oldRfid: e.oldRfid,
      newRfid: e.newRfid,
    );
  }

  // ── Planners ────────────────────────────────────────────────────────────

  Set<String> _collectAdminEmployeeNos(List<HikvisionUserInfo> users) {
    final out = <String>{};
    for (final u in users) {
      if ((u.userType ?? '').trim().toLowerCase() == 'administrator') {
        out.add(u.employeeNo.trim());
      }
    }
    return out;
  }

  List<HikReconcilePlanEntry> _planUpserts(
    List<Student> students,
    Map<String, HikvisionUserInfo> deviceUsersByEmployeeNo,
    List<HikvisionCardInfo> deviceCards,
  ) {
    final cardsByEmployeeNo = <String, String>{};
    for (final c in deviceCards) {
      final emp = (c.employeeNo ?? '').trim();
      if (emp.isEmpty) continue;
      cardsByEmployeeNo[emp] = c.rfidNumber.trim();
    }

    final out = <HikReconcilePlanEntry>[];
    for (final s in students) {
      final entry = _planOneUpsert(s, deviceUsersByEmployeeNo, cardsByEmployeeNo);
      if (entry != null) out.add(entry);
    }
    return out;
  }

  HikReconcilePlanEntry? _planOneUpsert(
    Student s,
    Map<String, HikvisionUserInfo> deviceUsersByEmployeeNo,
    Map<String, String> cardsByEmployeeNo,
  ) {
    final rfid = (s.rfidNumber ?? '').trim();
    // Students without a card don't belong on the device at all.
    if (rfid.isEmpty) return null;

    final emp = hikvisionEmployeeNoFor(s.userId);
    final personExists = deviceUsersByEmployeeNo.containsKey(emp);
    final deviceCard = cardsByEmployeeNo[emp] ?? '';

    final personOk = personExists;
    final cardOk = deviceCard == rfid;
    if (personOk && cardOk) return null;

    return HikReconcilePlanEntry(
      operation: HikOpType.upsertCard,
      userId: s.userId,
      employeeNo: emp,
      name: s.nama,
      oldRfid: deviceCard.isEmpty ? null : deviceCard,
      newRfid: rfid,
      reason: _explainUpsert(personExists, deviceCard, rfid),
    );
  }

  String _explainUpsert(bool personExists, String deviceCard, String wantedCard) {
    if (!personExists) return 'person belum ada di device';
    if (deviceCard.isEmpty) return 'kartu belum di-bind di device';
    return 'kartu device ($deviceCard) ≠ BE ($wantedCard)';
  }

  List<HikReconcilePlanEntry> _planPersonDeletes(
    List<HikvisionUserInfo> deviceUsers,
    Map<String, Student> localByEmployeeNo,
    Set<String> adminEmployeeNos,
  ) {
    final out = <HikReconcilePlanEntry>[];
    for (final u in deviceUsers) {
      final emp = u.employeeNo.trim();
      if (emp.isEmpty) continue;
      if (adminEmployeeNos.contains(emp)) continue;
      final local = localByEmployeeNo[emp];
      // Person exists on device but local has no row (student deleted), or
      // local has the row but no card (we keep persons aligned to cards).
      final shouldDelete =
          local == null || (local.rfidNumber ?? '').isEmpty;
      if (!shouldDelete) continue;
      out.add(HikReconcilePlanEntry(
        operation: HikOpType.deletePerson,
        userId: _userIdFromEmployeeNo(emp),
        employeeNo: emp,
        reason: local == null ? 'orphan person (tidak ada di local)' : 'student tanpa kartu',
      ));
    }
    return out;
  }

  List<HikReconcilePlanEntry> _planOrphanCardDeletes(
    List<HikvisionCardInfo> deviceCards,
    Map<String, Student> localByEmployeeNo,
    Set<String> adminEmployeeNos,
  ) {
    final localCardNos = <String>{};
    for (final s in localByEmployeeNo.values) {
      final c = (s.rfidNumber ?? '').trim();
      if (c.isNotEmpty) localCardNos.add(c);
    }

    final out = <HikReconcilePlanEntry>[];
    for (final c in deviceCards) {
      final rfid = c.rfidNumber.trim();
      if (rfid.isEmpty) continue;
      final ownerEmp = (c.employeeNo ?? '').trim();
      if (ownerEmp.isNotEmpty && adminEmployeeNos.contains(ownerEmp)) continue;
      if (localCardNos.contains(rfid)) continue;
      out.add(HikReconcilePlanEntry(
        operation: HikOpType.deleteCard,
        userId: ownerEmp.isEmpty ? '' : _userIdFromEmployeeNo(ownerEmp),
        employeeNo: ownerEmp,
        oldRfid: rfid,
        reason: 'orphan card (tidak ada di local)',
      ));
    }
    return out;
  }

  /// Inverse of `hikvisionEmployeeNoFor`: turns 32-char hex into UUID-string.
  /// Used so the HikOutbox row's userId matches what the worker expects.
  String _userIdFromEmployeeNo(String employeeNo) {
    final h = employeeNo;
    if (h.length != 32) return employeeNo;
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}'
        '-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
