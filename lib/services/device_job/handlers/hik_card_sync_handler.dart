import '../../../data/hikvision/isapi_client.dart';
import '../../../data/local/database.dart';
import '../device_job_handler.dart';

/// Reconciles a single student's Hikvision binding to match BE state.
///
/// Payload (BE → sijinak):
///   user_id      String, UUID with dashes (matches Drift Students.userId)
///   employee_no  String, UUID hex without dashes (Hikvision identifier)
///   name         String, full name (used when creating person)
///   old_rfid     String?, the previous card number, if any
///   new_rfid     String?, the new card number, null means remove
class HikCardSyncHandler implements DeviceJobHandler {
  final HikvisionDevicePort hik;
  final StudentStorePort db;

  HikCardSyncHandler({required this.hik, required this.db});

  @override
  String get jobType => 'hik.card.sync';

  @override
  Future<void> execute(DeviceJobPayload payload) async {
    final data = payload.data;
    final userId = data['user_id'] as String;
    final employeeNo = (data['employee_no'] as String?) ?? hikvisionEmployeeNoFor(userId);
    final name = (data['name'] as String?) ?? '';
    final oldRfid = data['old_rfid'] as String?;
    final newRfid = data['new_rfid'] as String?;

    await _ensurePerson(userId, employeeNo, name);
    await _revokeIfReplaced(oldRfid, newRfid);
    await _applyNewCard(employeeNo, newRfid);
    await _mirrorLocal(userId, newRfid);
  }

  Future<void> _ensurePerson(String userId, String employeeNo, String name) async {
    final student = await db.getStudentByUserId(userId);
    if (student != null && student.hikRegistered) return;

    final personName = name.isNotEmpty ? name : (student?.nama ?? employeeNo);
    await hik.upsertPerson(employeeNo: employeeNo, name: personName);
    await db.markHikRegistered(userId);
  }

  Future<void> _revokeIfReplaced(String? oldRfid, String? newRfid) async {
    if (oldRfid == null || oldRfid.isEmpty) return;
    if (oldRfid == newRfid) return;
    await hik.deleteCard(rfidNumber: oldRfid);
  }

  Future<void> _applyNewCard(String employeeNo, String? newRfid) async {
    if (newRfid == null || newRfid.isEmpty) return;
    await hik.upsertCard(rfidNumber: newRfid, employeeNo: employeeNo);
  }

  Future<void> _mirrorLocal(String userId, String? newRfid) async {
    if (newRfid == null || newRfid.isEmpty) {
      await db.removeCardFromStudent(userId);
      return;
    }
    await db.assignCardToStudent(userId, newRfid);
  }
}
