/// Response from `POST /api/desktop/students/{uid}/card`. The CardOutboxWorker
/// only needs the success/failure of the call, not the body, so no fields are
/// read today — kept faithful to the BE shape for future callers.
class CardSetResponseDTO {
  final String userId;
  final String? oldRfidNumber;
  final String? newRfidNumber;
  final String? jobId;

  const CardSetResponseDTO({
    required this.userId,
    this.jobId,
    this.oldRfidNumber,
    this.newRfidNumber,
  });

  factory CardSetResponseDTO.fromJson(Map<String, dynamic> json) {
    return CardSetResponseDTO(
      userId: json['user_id'] as String,
      jobId: json['job_id'] as String?,
      oldRfidNumber: json['old_rfid_number'] as String?,
      newRfidNumber: json['new_rfid_number'] as String?,
    );
  }
}
