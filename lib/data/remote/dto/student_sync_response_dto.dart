class StudentSyncResponseDTO {
  final String userId;
  final String nama;
  final String? nisn;
  final String? kelas;
  final String? rfidNumber;
  final String? noTelpWali;
  final String userType;

  const StudentSyncResponseDTO({
    required this.userId,
    required this.nama,
    required this.nisn,
    required this.kelas,
    required this.rfidNumber,
    required this.noTelpWali,
    required this.userType,
  });

  factory StudentSyncResponseDTO.fromJson(Map<String, dynamic> json) {
    return StudentSyncResponseDTO(
      userId: json['user_id'] as String,
      nama: json['nama_lengkap'] as String,
      nisn: json['nisn'] as String?,
      kelas: json['kelas_jurusan'] as String?,
      rfidNumber: json['rfid_number'] as String?,
      noTelpWali: json['no_telephone_wali'] as String?,
      userType: (json['user_type'] as String?) ?? 'siswa',
    );
  }

  bool get isSiswa => userType.toLowerCase() == 'siswa';
  bool get isAdmin {
    final r = userType.toLowerCase();
    return r == 'admin' || r == 'administrator';
  }
}
