class HikEvent {
  final String rfidNumber;
  final String? employeeNo;
  final DateTime dateTime;
  final int serialNo;
  // DS-K terminal: "checkIn" "checkOut" "breakIn" "breakOut" "overtimeIn" "overtimeOut"
  final String? attendanceStatus;

  HikEvent({
    required this.rfidNumber,
    this.employeeNo,
    required this.dateTime,
    required this.serialNo,
    this.attendanceStatus,
  });

  bool get isBreakIn {
    final s = attendanceStatus?.toLowerCase();
    return s == 'breakin' || s == 'checkin' || s == 'overtimein';
  }

  @override
  String toString() =>
      'HikEvent(rfid=$rfidNumber, serial=$serialNo, time=$dateTime, status=$attendanceStatus)';
}

class DeviceInfo {
  final String deviceName;
  final String model;
  final String serialNumber;
  final String firmwareVersion;

  DeviceInfo({
    required this.deviceName,
    required this.model,
    required this.serialNumber,
    required this.firmwareVersion,
  });

  @override
  String toString() => '$deviceName ($model)';
}
