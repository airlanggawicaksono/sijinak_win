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

  Future<TapRecord?> getExistingTodayRecord(String userId, String eventType) async {
    final today = await db.getTodayRecordsForStudent(userId);
    try {
      return today.firstWhere((r) => r.eventType == eventType);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleEvent(HikEvent event) async {
    if (event.rfidNumber.isEmpty) return;

    Student? student;
    if (event.employeeNo != null && event.employeeNo!.isNotEmpty) {
      final userId = _toUuid(event.employeeNo!);
      student = await db.getStudentByUserId(userId);
    }
    student ??= await db.getStudentByCard(event.rfidNumber);
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
