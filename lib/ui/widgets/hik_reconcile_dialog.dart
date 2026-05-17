import 'package:flutter/material.dart';

import '../../services/hik_outbox/hik_reconcile_service.dart';

/// Preview of what the reconcile button is about to enqueue.
/// Operator scans the counts + per-row reasons, then confirms or cancels.
/// No mutation happens here — caller does the enqueue on confirm.
class HikReconcileDialog extends StatelessWidget {
  final HikReconcilePlan plan;
  const HikReconcileDialog({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (plan.isEmpty) {
      return AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 36),
        title: const Text('Sudah Sinkron'),
        content: Text(
          'Device Hikvision sudah cocok dengan local DB.'
          '${plan.adminsSkipped > 0 ? '\n${plan.adminsSkipped} admin device dilewati.' : ''}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tutup'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Preview Sync ke Hikvision'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryRow(theme, plan),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.upserts.isNotEmpty)
                      _section(theme, 'Push kartu', plan.upserts, Colors.blue),
                    if (plan.personDeletes.isNotEmpty)
                      _section(theme, 'Hapus person', plan.personDeletes, Colors.red),
                    if (plan.cardDeletes.isNotEmpty)
                      _section(theme, 'Hapus orphan card', plan.cardDeletes, Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Local DB tetap source-of-truth. Device akan disesuaikan.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.outline),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.sync, size: 18),
          label: Text('Lanjutkan (${plan.total})'),
        ),
      ],
    );
  }

  Widget _summaryRow(ThemeData theme, HikReconcilePlan p) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(theme, 'Upsert', p.upserts.length, Colors.blue),
        _chip(theme, 'Hapus person', p.personDeletes.length, Colors.red),
        _chip(theme, 'Hapus card', p.cardDeletes.length, Colors.orange),
        if (p.adminsSkipped > 0)
          _chip(theme, 'Admin dilewati', p.adminsSkipped, Colors.grey),
      ],
    );
  }

  Widget _chip(ThemeData theme, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _section(
    ThemeData theme,
    String title,
    List<HikReconcilePlanEntry> entries,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title (${entries.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...entries.take(20).map((e) => _entryLine(theme, e)),
          if (entries.length > 20)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                '... dan ${entries.length - 20} lainnya',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryLine(ThemeData theme, HikReconcilePlanEntry e) {
    final id = e.name?.isNotEmpty == true ? e.name! : e.employeeNo;
    final tail = e.newRfid != null && e.newRfid!.isNotEmpty
        ? ' → ${e.newRfid}'
        : (e.oldRfid != null && e.oldRfid!.isNotEmpty ? ' (${e.oldRfid})' : '');
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
      child: Text(
        '• $id$tail · ${e.reason}',
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}
