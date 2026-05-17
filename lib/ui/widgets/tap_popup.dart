import 'package:flutter/material.dart';

import '../../data/local/database.dart';
import '../../services/attendance_service.dart';

class TapPopupResult {
  final String eventType; // absen_masuk, absen_keluar, izin
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

class TapPopupDialog extends StatefulWidget {
  final Student student;
  final AttendanceService attendanceService;
  final String? initialEventType;

  const TapPopupDialog({
    super.key,
    required this.student,
    required this.attendanceService,
    this.initialEventType,
  });

  @override
  State<TapPopupDialog> createState() => _TapPopupDialogState();
}

class _TapPopupDialogState extends State<TapPopupDialog> {
  String? _selected;
  final _keteranganCtrl = TextEditingController();
  final _perkiraanReturnCtrl = TextEditingController();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEventType != null) {
      _selected = widget.initialEventType;
    }
  }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    _perkiraanReturnCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTypeSelected(String type) async {
    setState(() {
      _selected = type;
      _isChecking = true;
    });

    try {
      if (type == 'izin') {
        setState(() => _isChecking = false);
        return;
      }

      final existing = await widget.attendanceService.getExistingTodayRecord(
        widget.student.userId,
        type,
      );

      if (existing != null) {
        final time = DateTime.fromMillisecondsSinceEpoch(existing.deviceTime * 1000);
        final timeStr =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

        final label = _getLabel(type);
        if (!mounted) return;
        final overwrite = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Sudah Ada Data $label'),
            content: Text('Anda sudah $label pada pukul $timeStr. Tetap perbarui data ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ya, Perbarui'),
              ),
            ],
          ),
        );

        if (overwrite == true) {
          if (!mounted) return;
          _confirm(existingRecordId: existing.id);
          return;
        }

        setState(() {
          _selected = null;
          _isChecking = false;
        });
        return;
      }

      _confirm();
    } catch (_) {
      setState(() => _isChecking = false);
    }
  }

  void _confirm({String? existingRecordId}) {
    if (_selected == null) return;

    final reason = _selected == 'izin' ? _keteranganCtrl.text.trim() : null;
    if (_selected == 'izin' && (reason == null || reason.isEmpty)) return;

    final perkiraanRaw = _perkiraanReturnCtrl.text.trim();
    final estimatedReturnAt = _selected == 'izin' ? _parsePerkiraanTime(perkiraanRaw) : null;
    if (_selected == 'izin' && perkiraanRaw.isNotEmpty && estimatedReturnAt == null) return;

    Navigator.of(context).pop(
      TapPopupResult(
        eventType: _selected!,
        reason: reason,
        estimatedReturnAt: estimatedReturnAt,
        existingRecordId: existingRecordId,
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
    return _parsePerkiraanTime(value) == null ? 'Format jam harus HH:mm (24 jam)' : null;
  }

  String _getLabel(String type) {
    if (type == 'absen_masuk') return 'Masuk';
    if (type == 'absen_keluar') return 'Keluar';
    return 'Izin';
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
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: maxDialogHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.initialEventType == 'izin') ...[
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
                          onPressed: _keteranganCtrl.text.trim().isEmpty ||
                                  _perkiraanErrorText() != null
                              ? null
                              : () => _confirm(),
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
                      ] else if (_isChecking)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                        )
                      else ...[
                        Text(
                          'PILIH JENIS ABSENSI',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.outline,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _ActionButton(
                              label: 'MASUK',
                              icon: Icons.login_rounded,
                              color: Colors.green,
                              selected: _selected == 'absen_masuk',
                              onTap: () => _onTypeSelected('absen_masuk'),
                            ),
                            const SizedBox(width: 12),
                            _ActionButton(
                              label: 'KELUAR',
                              icon: Icons.logout_rounded,
                              color: Colors.blue,
                              selected: _selected == 'absen_keluar',
                              onTap: () => _onTypeSelected('absen_keluar'),
                            ),
                            const SizedBox(width: 12),
                            _ActionButton(
                              label: 'IZIN',
                              icon: Icons.assignment_return_rounded,
                              color: Colors.orange,
                              selected: _selected == 'izin',
                              onTap: () => _onTypeSelected('izin'),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: _selected == 'izin'
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: _keteranganCtrl,
                                        autofocus: true,
                                        maxLines: 2,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          labelText: 'Alasan Izin Keluar',
                                          alignLabelWithHint: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          prefixIcon: const Icon(Icons.edit_note),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Jam saat ini: $nowStr',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colors.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _perkiraanReturnCtrl,
                                        keyboardType: TextInputType.datetime,
                                        onChanged: (_) => setState(() {}),
                                        decoration: InputDecoration(
                                          labelText: 'Perkiraan kembali (opsional)',
                                          hintText: 'Contoh: 15:03',
                                          helperText: 'Gunakan format 24 jam (HH:mm)',
                                          errorText: _perkiraanErrorText(),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          prefixIcon: const Icon(Icons.schedule),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      FilledButton(
                                        onPressed: _keteranganCtrl.text.trim().isEmpty ||
                                                _perkiraanErrorText() != null
                                            ? null
                                            : () => _confirm(),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.orange.shade700,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: const Text(
                                          'SIMPAN IZIN',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
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
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.2),
              width: selected ? 3 : 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? color : Colors.grey.shade600,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
