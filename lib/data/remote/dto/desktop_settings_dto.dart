/// BE-canonical desktop settings cached by sijinak.
///
/// Currently only [lateCutoffTime] but kept as a class (not a bare type)
/// so future fields (work hours, holiday flags) add without breaking call sites.
class DesktopSettingsDTO {
  /// Cutoff time of day after which `absen_masuk` is classified TERLAMBAT.
  /// Encoded as `HH:MM` over the wire (BE strips seconds via HhmmTime).
  final String lateCutoffTime;

  const DesktopSettingsDTO({required this.lateCutoffTime});

  factory DesktopSettingsDTO.fromJson(Map<String, dynamic> json) {
    return DesktopSettingsDTO(
      lateCutoffTime: (json['late_cutoff_time'] as String?) ?? '07:15',
    );
  }

  /// Parses [lateCutoffTime] to (hour, minute). Returns null if malformed.
  ({int hour, int minute})? get lateCutoffHm {
    final parts = lateCutoffTime.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (hour: h, minute: m);
  }

  /// True iff [moment]'s wall-clock time-of-day is strictly past the cutoff,
  /// matching BE's `>` comparison in `_handle_absen_masuk`.
  bool isLateAt(DateTime moment) {
    final hm = lateCutoffHm;
    if (hm == null) return false;
    final cutoffMinutes = hm.hour * 60 + hm.minute;
    final momentMinutes = moment.hour * 60 + moment.minute;
    return momentMinutes > cutoffMinutes;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DesktopSettingsDTO && other.lateCutoffTime == lateCutoffTime);

  @override
  int get hashCode => lateCutoffTime.hashCode;
}
