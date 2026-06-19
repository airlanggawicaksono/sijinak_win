import 'package:flutter/material.dart';

import '../../data/local/database.dart';

class TapPopupResult {
  final String eventType; // always 'izin' from this dialog
  final String? reason;
  final DateTime? estimatedReturnAt;
  final String? existingRecordId;

  const TapPopupResult({
    required this.eventType,
    this.reason,
    this.estimatedReturnAt,
    this.existingRecordId,
  });
}

/// Izin-only popup, shown when the device reports a tap-IN event. Collects the
/// reason + optional return time; the caller then prints the ticket and saves.
/// Absen masuk/keluar (tap-OUT) is recorded silently — no popup. The old
/// MASUK/KELUAR/IZIN chooser was removed: every caller opens this in izin mode.
class TapPopupDialog extends StatefulWidget {
  final Student student;

  const TapPopupDialog({super.key, required this.student});

  @override
  State<TapPopupDialog> createState() => _TapPopupDialogState();
}

class _TapPopupDialogState extends State<TapPopupDialog> {
  final _keteranganCtrl = TextEditingController();
  final _perkiraanReturnCtrl = TextEditingController();

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    _perkiraanReturnCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _keteranganCtrl.text.trim();
    if (reason.isEmpty) return;

    final perkiraanRaw = _perkiraanReturnCtrl.text.trim();
    final estimatedReturnAt = _parsePerkiraanTime(perkiraanRaw);
    if (perkiraanRaw.isNotEmpty && estimatedReturnAt == null) return;

    Navigator.of(context).pop(
      TapPopupResult(
        eventType: 'izin',
        reason: reason,
        estimatedReturnAt: estimatedReturnAt,
      ),
    );
  }

  DateTime? _parsePerkiraanTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final match = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$').firstMatch(value);
    if (match == null) return null;

    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String? _perkiraanErrorText() {
    final value = _perkiraanReturnCtrl.text.trim();
    if (value.isEmpty) return null;
    return _parsePerkiraanTime(value) == null
        ? 'Format jam harus HH:mm (24 jam)'
        : null;
  }

  String _eventDetail(Student student) {
    return [
      if (student.nisn != null) 'NISN: ${student.nisn!}',
      if (student.kelas != null) student.kelas!,
    ].join(' · ');
  }

  String _formatNow24h(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _canSave =>
      _keteranganCtrl.text.trim().isNotEmpty && _perkiraanErrorText() == null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final student = widget.student;
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.86;
    final nowStr = _formatNow24h(DateTime.now());

    return Dialog(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: maxDialogHeight),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(theme, colors, student),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _keteranganCtrl,
                        autofocus: true,
                        maxLines: 5,
                        onChanged: (_) => setState(() {}),
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Alasan Izin Keluar',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Jam saat ini: $nowStr',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _perkiraanReturnCtrl,
                        keyboardType: TextInputType.datetime,
                        onChanged: (_) => setState(() {}),
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Perkiraan kembali (opsional)',
                          hintText: 'Contoh: 15:03',
                          helperText: 'Gunakan format 24 jam (HH:mm)',
                          errorText: _perkiraanErrorText(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          prefixIcon: const Icon(Icons.schedule),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _canSave ? _confirm : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('SIMPAN IZIN'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                style: TextButton.styleFrom(
                  foregroundColor: colors.outline,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('BATAL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, ColorScheme colors, Student student) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(Icons.person, size: 36, color: colors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.nama,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _eventDetail(student),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tutup',
          onPressed: () => Navigator.of(context).pop(null),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
