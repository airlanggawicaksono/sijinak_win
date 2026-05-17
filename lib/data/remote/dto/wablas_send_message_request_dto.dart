class WablasSendMessageRequestDTO {
  final String phone;
  final String message;

  const WablasSendMessageRequestDTO({
    required this.phone,
    required this.message,
  });

  Map<String, String> toFormPayload() {
    return {
      'phone': phone,
      'message': message,
    };
  }
}

