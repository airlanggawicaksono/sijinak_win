class IzinDispatchResultDTO {
  final bool backendAccepted;
  final DateTime? backendPublishedAt;
  final bool wablasSent;
  final String? backendError;
  final String? wablasError;

  const IzinDispatchResultDTO({
    required this.backendAccepted,
    required this.backendPublishedAt,
    required this.wablasSent,
    this.backendError,
    this.wablasError,
  });
}

