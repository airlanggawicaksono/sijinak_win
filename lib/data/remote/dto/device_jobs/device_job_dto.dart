class DeviceJobDTO {
  final String id;
  final String jobType;
  final Map<String, dynamic> payload;
  final String status;
  final String? relatedUserId;
  final int retryCount;
  final String? lastError;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final String? claimedBy;
  final DateTime? claimedAt;

  const DeviceJobDTO({
    required this.id,
    required this.jobType,
    required this.payload,
    required this.status,
    required this.retryCount,
    required this.createdAt,
    this.relatedUserId,
    this.lastError,
    this.nextRetryAt,
    this.claimedBy,
    this.claimedAt,
  });

  factory DeviceJobDTO.fromJson(Map<String, dynamic> json) {
    return DeviceJobDTO(
      id: json['id'] as String,
      jobType: json['job_type'] as String,
      payload: (json['payload'] as Map<String, dynamic>? ?? const {}),
      status: json['status'] as String,
      relatedUserId: json['related_user_id'] as String?,
      retryCount: (json['retry_count'] as num).toInt(),
      lastError: json['last_error'] as String?,
      nextRetryAt: _parseTs(json['next_retry_at'] as String?),
      createdAt: _parseTs(json['created_at'] as String?) ?? DateTime.now(),
      claimedBy: json['claimed_by'] as String?,
      claimedAt: _parseTs(json['claimed_at'] as String?),
    );
  }

  static DateTime? _parseTs(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class ClaimResponseDTO {
  final bool claimed;
  final DeviceJobDTO? job;

  const ClaimResponseDTO({required this.claimed, this.job});

  factory ClaimResponseDTO.fromJson(Map<String, dynamic> json) {
    final raw = json['job'] as Map<String, dynamic>?;
    return ClaimResponseDTO(
      claimed: json['claimed'] as bool? ?? false,
      job: raw == null ? null : DeviceJobDTO.fromJson(raw),
    );
  }
}

class CardSetResponseDTO {
  final String userId;
  final String? oldRfidNumber;
  final String? newRfidNumber;
  final String jobId;

  const CardSetResponseDTO({
    required this.userId,
    required this.jobId,
    this.oldRfidNumber,
    this.newRfidNumber,
  });

  factory CardSetResponseDTO.fromJson(Map<String, dynamic> json) {
    return CardSetResponseDTO(
      userId: json['user_id'] as String,
      jobId: json['job_id'] as String,
      oldRfidNumber: json['old_rfid_number'] as String?,
      newRfidNumber: json['new_rfid_number'] as String?,
    );
  }
}
