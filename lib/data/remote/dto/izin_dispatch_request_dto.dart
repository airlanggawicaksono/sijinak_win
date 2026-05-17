class IzinDispatchRequestDTO {
  final String recordId;
  final String userId;
  final DateTime deviceTime;
  final String reason;
  final DateTime? perkiraanKembali;
  final String studentName;
  final String? nisn;

  const IzinDispatchRequestDTO({
    required this.recordId,
    required this.userId,
    required this.deviceTime,
    required this.reason,
    required this.perkiraanKembali,
    required this.studentName,
    required this.nisn,
  });

  Map<String, dynamic> toAttendanceEventPayload() {
    return {
      'record_id': recordId,
      'user_id': userId,
      'event_type': 'izin',
      'device_time': deviceTime.toIso8601String(),
      'reason': reason,
      'perkiraan_kembali': perkiraanKembali?.toIso8601String(),
    };
  }
}

