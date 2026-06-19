import 'dart:async';
import '../data/local/database.dart';
import '../data/hikvision/hik_event.dart';
import 'hikvision_service.dart';

class AttendanceService {
  final AttendanceStorePort db;
  final HikvisionService hikService;

  StreamSubscription? _sub;
  bool _running = false;

  void Function(HikEvent event, Student student, String eventType)? onAutoAttendance;
  void Function(HikEvent event, Student student)? onIzinRequired;
  void Function(Student student)? onAlreadySignedOff;

  AttendanceService({required this.db, required this.hikService});

  void start() {
    if (_running) return;
    _running = true;
    // Defensive: a previous run may have crashed inside CardScanDialog.dispose
    // before endCapture() ran. Clear any stale depth so attendance isn't
    // permanently gagged.
    hikService.resetCapture();
    _sub = hikService.events.listen(_handleEvent);
  }

  void stop() {
    _running = false;
    _sub?.cancel();
    _sub = null;
  }

  String _toUuid(String employeeNo) {
    final h = employeeNo;
    if (h.length != 32) return employeeNo;
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}'
        '-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> _handleEvent(HikEvent event) async {
    if (event.rfidNumber.isEmpty) return;
    // While CardScanDialog is open, taps are consumed by the dialog (treated
    // as "assign this card to the student being edited"). Don't double-fire
    // absen/izin against the existing owner.
    if (hikService.isCapturing) return;

    // Only a DEVICE-resolved person counts as a real absensi/izin tap. A
    // recognized card carries employeeNoString (the device matched it to a
    // person). An unregistered/illegal card emits an alertStream event with a
    // cardNo but NO employeeNo — the device never granted it. Those "alerts"
    // are used solely by CardScanDialog for assignment; they must never drive
    // attendance. (Previously a getStudentByCard fallback matched the local DB
    // even for cards the device rejected, firing phantom absen.)
    final employeeNo = event.employeeNo;
    if (employeeNo == null || employeeNo.isEmpty) return;
    final student = await db.getStudentByUserId(_toUuid(employeeNo));
    if (student == null) return;

    // Break In → show izin popup (reason + ticket print required).
    if (event.isBreakIn) {
      onIzinRequired?.call(event, student);
      return;
    }

    final today = await db.getTodayRecordsForStudent(student.userId);
    final alreadyMasuk = today.any((r) => r.eventType == 'absen_masuk');
    final alreadyKeluar = today.any((r) => r.eventType == 'absen_keluar');

    if (alreadyMasuk && alreadyKeluar) {
      onAlreadySignedOff?.call(student);
      return;
    }

    onAutoAttendance?.call(event, student, alreadyMasuk ? 'absen_keluar' : 'absen_masuk');
  }
}
