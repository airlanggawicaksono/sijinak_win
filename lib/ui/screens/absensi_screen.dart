import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/izin_payload.dart';

class AbsensiScreen extends ConsumerStatefulWidget {
  const AbsensiScreen({super.key});

  @override
  ConsumerState<AbsensiScreen> createState() => _AbsensiScreenState();
}

class _AbsensiScreenState extends ConsumerState<AbsensiScreen> {
  @override
  Widget build(BuildContext context) {
    final recentRecords = ref.watch(recentRecordsProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Absensi Monitor',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'WebView dihapus. Monitor data absensi langsung dari data lokal perangkat.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          pendingCount.when(
            data: (count) => Card(
              child: ListTile(
                leading: const Icon(Icons.sync_problem_outlined),
                title: const Text('Pending Sync'),
                subtitle: Text('$count record belum terkirim ke backend'),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load pending count: $e'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: recentRecords.when(
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(child: Text('Belum ada record absensi.'));
                }
                return Card(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      final dt = DateTime.fromMillisecondsSinceEpoch(
                        row.deviceTime * 1000,
                      );
                      final students = ref.read(allStudentsProvider).asData?.value ?? [];
                      final userIdFromRecord = _extractUserIdFromRecordId(row.id);
                      final student = userIdFromRecord != null
                          ? students.where((s) => s.userId == userIdFromRecord).firstOrNull
                          : students.where((s) => s.rfidNumber == row.rfidNumber).firstOrNull;
                      final displayName = student?.nama ?? 'Unknown';
                      return ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: Text('$displayName - ${row.rfidNumber}'),
                        subtitle: Text(_formatRecordSubtitle(row.eventType, dt, row.reason)),
                        trailing: row.publishedAt == null
                            ? const Icon(Icons.cloud_off, color: Colors.orange)
                            : const Icon(Icons.cloud_done, color: Colors.green),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load records: $e')),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime24(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatRecordSubtitle(String eventType, DateTime dt, String? reasonRaw) {
    final timeOut = _formatTime24(dt);
    if (eventType != 'izin') {
      return '$eventType | $timeOut';
    }

    final izin = decodeIzinReasonPayload(reasonRaw);
    final kembali = izin.perkiraanKembali == null
        ? '-'
        : '${izin.perkiraanKembali!.hour.toString().padLeft(2, '0')}:${izin.perkiraanKembali!.minute.toString().padLeft(2, '0')}';
    final alasan = izin.reason?.trim();
    final alasanText = (alasan == null || alasan.isEmpty) ? '-' : alasan;
    return 'Izin\nKeluar: $timeOut\nPerkiraan kembali: $kembali\nAlasan: $alasanText';
  }

  String? _extractUserIdFromRecordId(String recordId) {
    final match = RegExp(
      r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})_',
    ).firstMatch(recordId);
    return match?.group(1);
  }
}
