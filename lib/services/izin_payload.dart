import 'dart:convert';

const _izinPayloadPrefix = '__IZIN_JSON__';

class IzinPayload {
  final String? reason;
  final DateTime? perkiraanKembali;

  const IzinPayload({this.reason, this.perkiraanKembali});
}

String? encodeIzinReasonPayload({
  required String? reason,
  DateTime? perkiraanKembali,
}) {
  final cleanReason = reason?.trim();
  if ((cleanReason == null || cleanReason.isEmpty) && perkiraanKembali == null) {
    return null;
  }
  if (perkiraanKembali == null) return cleanReason;

  return _izinPayloadPrefix +
      jsonEncode({
        'reason': cleanReason,
        'perkiraan_kembali': perkiraanKembali.toIso8601String(),
      });
}

IzinPayload decodeIzinReasonPayload(String? raw) {
  if (raw == null || raw.isEmpty) return const IzinPayload();
  if (!raw.startsWith(_izinPayloadPrefix)) {
    return IzinPayload(reason: raw);
  }
  try {
    final map = jsonDecode(raw.substring(_izinPayloadPrefix.length)) as Map<String, dynamic>;
    final reason = (map['reason'] as String?)?.trim();
    final perkiraan = map['perkiraan_kembali'] as String?;
    return IzinPayload(
      reason: (reason == null || reason.isEmpty) ? null : reason,
      perkiraanKembali: perkiraan == null ? null : DateTime.tryParse(perkiraan),
    );
  } catch (_) {
    return IzinPayload(reason: raw);
  }
}
