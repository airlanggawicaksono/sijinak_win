import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../data/remote/api_client.dart';
import '../../providers/providers.dart';
import '../../services/student_service.dart';

class BulkCardAssignDialog extends ConsumerStatefulWidget {
  final List<Map<String, String>> rows;
  final AppConfig config;
  final BackendApiPort api;

  const BulkCardAssignDialog({
    super.key,
    required this.rows,
    required this.config,
    required this.api,
  });

  @override
  ConsumerState<BulkCardAssignDialog> createState() =>
      _BulkCardAssignDialogState();
}

class _BulkCardAssignDialogState extends ConsumerState<BulkCardAssignDialog> {
  BulkCardAssignProgress? _progress;
  bool _started = false;

  void _start() {
    setState(() => _started = true);
    final service = ref.read(studentServiceProvider);
    final stream = service.bulkAssignCards(rows: widget.rows, api: widget.api);
    stream.listen((p) {
      if (mounted) setState(() => _progress = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hikReady = ref.watch(hikvisionReadyProvider);

    if (!_started) {
      final blocker = !hikReady
          ? 'Hikvision offline — import diblokir agar BE & device tidak melenceng.'
          : null;
      return AlertDialog(
        title: const Text('Import Kartu CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ditemukan ${widget.rows.length} baris data.\n'
              'Lanjutkan assign kartu via server?',
            ),
            if (blocker != null) ...[
              const SizedBox(height: 8),
              Text(
                blocker,
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: hikReady ? _start : null,
            child: const Text('Mulai'),
          ),
        ],
      );
    }

    final p = _progress;
    if (p == null) {
      return const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final fraction = p.total > 0 ? p.current / p.total : 0.0;

    if (p.done) {
      return AlertDialog(
        title: const Text('Selesai diantrekan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kartu yang berhasil diantrekan akan disinkron ke server di latar belakang. Pantau status di tabel siswa.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text('Diantrekan: ${p.success}',
                style: TextStyle(color: Colors.green[700])),
            if (p.skipped > 0)
              Text('Dilewati: ${p.skipped}',
                  style: TextStyle(color: colors.outline)),
            if (p.failed > 0)
              Text('Gagal: ${p.failed}',
                  style: TextStyle(color: colors.error)),
            if (p.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Detail error:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: p.errors
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text('- $e',
                                  style: TextStyle(
                                      fontSize: 12, color: colors.error)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Mengantrekan Kartu...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: fraction),
          const SizedBox(height: 12),
          Text('${p.current} / ${p.total}'),
          if (p.currentNisn.isNotEmpty)
            Text('NISN: ${p.currentNisn}',
                style: TextStyle(color: colors.outline, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('OK: ${p.success} ',
                  style: TextStyle(color: Colors.green[700], fontSize: 12)),
              if (p.skipped > 0)
                Text('Skip: ${p.skipped} ',
                    style: TextStyle(color: colors.outline, fontSize: 12)),
              if (p.failed > 0)
                Text('Fail: ${p.failed}',
                    style: TextStyle(color: colors.error, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
