import '../../../data/hikvision/isapi_client.dart';
import '../device_job_handler.dart';

/// Deletes a person (and any lingering card) from the Hikvision device.
/// Triggered by the `hik.person.delete` DeviceJob that BE enqueues when a
/// student is removed.
///
/// Payload (BE → sijinak):
///   user_id      String — dashed UUID (informational only here)
///   employee_no  String — 32-char hex used as Hikvision personNo
///   rfid_number  String? — last known card on the student, may be null
///
/// Order matters: revoke card first so the device doesn't keep a card row
/// pointing at a non-existent person.
class HikPersonDeleteHandler implements DeviceJobHandler {
  final HikvisionDevicePort hik;

  HikPersonDeleteHandler({required this.hik});

  @override
  String get jobType => 'hik.person.delete';

  @override
  Future<void> execute(DeviceJobPayload payload) async {
    final data = payload.data;
    final employeeNo = (data['employee_no'] as String?) ??
        hikvisionEmployeeNoFor(data['user_id'] as String);
    final rfid = data['rfid_number'] as String?;

    await _safeDeleteCard(rfid);
    await _safeDeletePerson(employeeNo);
  }

  Future<void> _safeDeleteCard(String? rfid) async {
    if (rfid == null || rfid.isEmpty) return;
    try {
      await hik.deleteCard(rfidNumber: rfid);
    } catch (_) {
      // Card may not exist on device anymore; person delete still proceeds.
    }
  }

  Future<void> _safeDeletePerson(String employeeNo) async {
    if (employeeNo.isEmpty) return;
    await hik.deletePerson(employeeNo: employeeNo);
  }
}
