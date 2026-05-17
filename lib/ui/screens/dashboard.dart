import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../services/app_pubsub.dart';
import '../../services/izin_payload.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _initialSyncDone = false;

  @override
  void initState() {
    super.initState();
    AppPubSub.subscribe(
      key: AppPubSubTopics.globalSynced,
      context: this,
      handler: (_, _) => _refreshLocalViews(),
    );
    AppPubSub.subscribe(
      key: AppPubSubTopics.studentSynced,
      context: this,
      handler: (_, _) => _refreshLocalViews(),
    );
    _autoSync();
  }

  @override
  void dispose() {
    AppPubSub.unsubscribe(context: this);
    super.dispose();
  }

  Future<void> _autoSync() async {
    if (_initialSyncDone) return;
    _initialSyncDone = true;
    final config = ref.read(configProvider).asData?.value;
    if (config != null && config.isServerConfigured) {
      await ref.read(globalSyncProvider.notifier).syncAll();
    }
  }

  Future<void> _refreshAll() async {
    final config = ref.read(configProvider).asData?.value;
    if (config != null && config.isServerConfigured) {
      await ref.read(globalSyncProvider.notifier).syncAll();
    } else {
      ref.invalidate(allStudentsProvider);
      ref.invalidate(recentRecordsProvider);
      ref.invalidate(pendingSyncCountProvider);
    }
  }

  void _refreshLocalViews() {
    ref.invalidate(allStudentsProvider);
    ref.invalidate(recentRecordsProvider);
    ref.invalidate(pendingSyncCountProvider);
  }

  String _studentName(String rfidNumber, String recordId) {
    final students = ref.read(allStudentsProvider).asData?.value ?? [];
    final userIdFromRecord = _extractUserIdFromRecordId(recordId);
    final student = userIdFromRecord != null
        ? students.where((s) => s.userId == userIdFromRecord).firstOrNull
        : students.where((s) => s.rfidNumber == rfidNumber).firstOrNull;
    return student?.nama ?? rfidNumber;
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);
    final syncState = ref.watch(globalSyncProvider);
    final studentState = ref.watch(studentSyncProvider);
    final pendingAsync = ref.watch(pendingSyncCountProvider);
    final recordsAsync = ref.watch(recentRecordsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.door_back_door_outlined,
                  color: colors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Sijinak',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const Spacer(),
                syncState.when(
                  data: (s) => s.syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) =>
                      const Icon(Icons.sync_problem, color: Colors.red),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ).then((_) => _refreshAll()),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),

          // ── Status Cards ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                _buildStatusCard(
                  context,
                  icon: Icons.router,
                  label: 'Hikvision Reader',
                  value:
                      configAsync.whenOrNull(
                        data: (c) =>
                            c.isHikvisionConfigured ? 'Ready' : 'Not set',
                      ) ??
                      '...',
                  color:
                      configAsync.whenOrNull(
                        data: (c) =>
                            c.isHikvisionConfigured ? Colors.green : Colors.red,
                      ) ??
                      Colors.grey,
                ),
                const SizedBox(width: 12),
                _buildStatusCard(
                  context,
                  icon: Icons.cloud,
                  label: 'Server',
                  value:
                      configAsync.whenOrNull(
                        data: (c) =>
                            c.isServerConfigured ? 'Connected' : 'Not set',
                      ) ??
                      '...',
                  color:
                      configAsync.whenOrNull(
                        data: (c) =>
                            c.isServerConfigured ? Colors.green : Colors.red,
                      ) ??
                      Colors.grey,
                ),
                const SizedBox(width: 12),
                _buildStatusCard(
                  context,
                  icon: Icons.people,
                  label: 'Students',
                  value: studentState.when(
                    data: (s) => '${s.count}',
                    loading: () => '...',
                    error: (_, _) => '?',
                  ),
                  color: Colors.blue,
                  subtitle: studentState.whenOrNull(
                    data: (s) {
                      if (s.lastSyncedAt != null) {
                        final t = s.lastSyncedAt!;
                        return 'Synced ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusCard(
                  context,
                  icon: Icons.cloud_upload,
                  label: 'Pending',
                  value: pendingAsync.when(
                    data: (n) => '$n',
                    loading: () => '...',
                    error: (_, _) => '?',
                  ),
                  onTap: _refreshAll,
                  color:
                      pendingAsync.whenOrNull(
                        data: (n) => n > 0 ? Colors.orange : Colors.green,
                      ) ??
                      Colors.grey,
                ),
              ],
            ),
          ),

          // ── Sync error/success banner ──────────────────────────
          syncState.whenOrNull(
                data: (s) {
                  if (s.error != null) {
                    return _SyncBanner(
                      message: 'Sync failed: ${s.error}',
                      color: Colors.red,
                      onRetry: _refreshAll,
                    );
                  }
                  if (s.lastAttendanceSynced != null &&
                      s.lastAttendanceSynced! > 0) {
                    return _SyncBanner(
                      message:
                          'Successfully synced ${s.lastAttendanceSynced} records to server.',
                      color: Colors.green,
                      icon: Icons.check_circle_outline,
                    );
                  }
                  return null;
                },
              ) ??
              const SizedBox.shrink(),

          // ── Recent Events ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Text(
                  'Recent Events',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                recordsAsync.whenOrNull(
                      data: (records) => Text(
                        '${records.length} records',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.outline,
                        ),
                      ),
                    ) ??
                    const SizedBox.shrink(),
              ],
            ),
          ),

          Expanded(
            child: recordsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (records) => records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.contactless,
                            size: 64,
                            color: colors.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No events yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.outline,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure Hikvision reader and tap a card to start',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.outlineVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final time = DateTime.fromMillisecondsSinceEpoch(
                          record.deviceTime * 1000,
                        );
                        final timeStr =
                            '${time.hour.toString().padLeft(2, '0')}:'
                            '${time.minute.toString().padLeft(2, '0')}:'
                            '${time.second.toString().padLeft(2, '0')}';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _eventColor(
                              record.eventType,
                            ).withValues(alpha: 0.1),
                            child: Icon(
                              _eventIcon(record.eventType),
                              color: _eventColor(record.eventType),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            _studentName(record.rfidNumber, record.id),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            '${_eventLabel(record.eventType)} · $timeStr'
                            '${record.reason != null ? ' · ${decodeIzinReasonPayload(record.reason).reason ?? record.reason}' : ''}',
                          ),
                          trailing: Icon(
                            record.publishedAt != null
                                ? Icons.cloud_done
                                : Icons.cloud_off_outlined,
                            color: record.publishedAt != null
                                ? Colors.green
                                : colors.outlineVariant,
                            size: 18,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _eventIcon(String eventType) {
    switch (eventType) {
      case 'absen_masuk':
        return Icons.login;
      case 'absen_keluar':
        return Icons.logout;
      case 'izin':
        return Icons.description;
      default:
        return Icons.contactless;
    }
  }

  Color _eventColor(String eventType) {
    switch (eventType) {
      case 'absen_masuk':
        return Colors.green;
      case 'absen_keluar':
        return Colors.blue;
      case 'izin':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _eventLabel(String eventType) {
    switch (eventType) {
      case 'absen_masuk':
        return 'Masuk';
      case 'absen_keluar':
        return 'Keluar';
      case 'izin':
        return 'Izin';
      default:
        return eventType;
    }
  }

  String? _extractUserIdFromRecordId(String recordId) {
    final match = RegExp(
      r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})_',
    ).firstMatch(recordId);
    return match?.group(1);
  }
}

class _SyncBanner extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final VoidCallback? onRetry;

  const _SyncBanner({
    required this.message,
    required this.color,
    this.icon = Icons.warning_amber,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
