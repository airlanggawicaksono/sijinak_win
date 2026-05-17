import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../data/local/database.dart';
import '../data/remote/api_client.dart';
import '../data/remote/desktop_event_bus.dart';
import '../services/absensi/absensi_invalidation_subscriber.dart';
import '../services/card_outbox/card_outbox_worker.dart';
import '../services/device_job/handlers/hik_person_delete_handler.dart';
import '../services/settings/desktop_settings_store.dart';
import '../services/students/student_deleted_subscriber.dart';
import '../services/attendance_service.dart';
import '../services/hikvision_service.dart';
import '../services/student_service.dart';
import '../services/sync_service.dart';
import '../services/app_pubsub.dart';
import '../services/ticket_printer_service.dart';
import '../services/izin_dispatch_service.dart';
import '../services/device_job/device_job_worker.dart';
import '../services/device_job/handlers/hik_card_sync_handler.dart';
import '../data/hikvision/alert_stream.dart';
import '../data/hikvision/isapi_client.dart';

// Database - singleton
final databaseProvider = Provider<AppDatabase>((_) => AppDatabase.instance);

// Config - async, loaded from disk
final configProvider =
    AsyncNotifierProvider<ConfigNotifier, AppConfig>(ConfigNotifier.new);

class ConfigNotifier extends AsyncNotifier<AppConfig> {
  @override
  Future<AppConfig> build() => AppConfig.load();

  Future<void> updateConfig(AppConfig config) async {
    await config.save();
    state = AsyncData(config);
  }
}

// Hikvision service - singleton
final hikvisionServiceProvider = Provider<HikvisionService>((_) {
  return HikvisionService();
});

final hikvisionStatusProvider = StreamProvider<AlertStreamStatus>((ref) {
  final service = ref.watch(hikvisionServiceProvider);
  return service.status;
});

final hikvisionReadyProvider = Provider<bool>((ref) {
  final config = ref.watch(configProvider).asData?.value;
  if (config == null || !config.isHikvisionConfigured) return false;

  final service = ref.watch(hikvisionServiceProvider);
  final status = ref.watch(hikvisionStatusProvider).asData?.value ??
      service.currentStatus;
  return status == AlertStreamStatus.connected;
});

// Student service
final studentServiceProvider = Provider<StudentService>((ref) {
  return StudentService(ref.read(databaseProvider));
});

// Attendance service - singleton
final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(
    db: ref.read(databaseProvider),
    hikService: ref.read(hikvisionServiceProvider),
  );
});

// Sync service - singleton
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.read(databaseProvider));
});

final ticketPrinterServiceProvider = Provider<TicketPrinterPort>((_) {
  return TicketPrinterService();
});

final izinDispatchServiceProvider = Provider<IzinDispatchService>((_) {
  return IzinDispatchService();
});

// Dashboard data
final recentRecordsProvider = FutureProvider<List<TapRecord>>((ref) {
  final db = ref.read(databaseProvider);
  return db.getRecentRecords();
});

final allStudentsProvider = FutureProvider<List<Student>>((ref) {
  final db = ref.read(databaseProvider);
  return db.getAllStudents();
});

// Student sync
final studentSyncProvider =
    AsyncNotifierProvider<StudentSyncNotifier, StudentSyncState>(
        StudentSyncNotifier.new);

class StudentSyncState {
  final int count;
  final DateTime? lastSyncedAt;
  final bool syncing;
  final String? error;

  const StudentSyncState({
    this.count = 0,
    this.lastSyncedAt,
    this.syncing = false,
    this.error,
  });

  StudentSyncState copyWith({
    int? count,
    DateTime? lastSyncedAt,
    bool? syncing,
    String? error,
  }) =>
      StudentSyncState(
        count: count ?? this.count,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        syncing: syncing ?? this.syncing,
        error: error,
      );
}

class StudentSyncNotifier extends AsyncNotifier<StudentSyncState> {
  @override
  Future<StudentSyncState> build() async {
    final db = ref.read(databaseProvider);
    final count = await db.getStudentCount();
    return StudentSyncState(count: count);
  }

  Future<void> syncStudents() async {
    final config = ref.read(configProvider).asData?.value;
    if (config == null || !config.isServerConfigured) return;

    state = AsyncData(
      (state.asData?.value ?? const StudentSyncState()).copyWith(
        syncing: true,
        error: null,
      ),
    );

    try {
      final BackendApiPort api = ApiClient.fromConfig(config);
      final data = await api.fetchStudents();
      final db = ref.read(databaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final rows = data
          .where((s) => s.isSiswa)
          .map((s) => StudentsCompanion(
                userId: Value(s.userId),
                nama: Value(s.nama),
                nisn: Value(s.nisn),
                kelas: Value(s.kelas),
                rfidNumber: Value(s.rfidNumber),
                noTelpWali: Value(s.noTelpWali),
                syncedAt: Value(now),
              ))
          .toList();

      final serverUserIds = data
          .where((s) => s.isSiswa)
          .map((s) => s.userId)
          .toSet();

      final protectedUserIds = data
          .where((s) => s.isAdmin)
          .map((s) => s.userId)
          .toSet();

      await db.syncStudentsSnapshot(
        rows: rows,
        serverUserIds: serverUserIds,
        protectedUserIds: protectedUserIds,
      );

      // Hikvision additions/replacements are handled out-of-band by the
      // DeviceJob worker (BE enqueues hik.card.sync jobs on every card mutation).
      // Stale entries on the device are pruned periodically via cleanupStaleFromHikvision.
      if (config.isHikvisionConfigured) {
        await ref.read(studentServiceProvider).cleanupStaleFromHikvision(config: config);
      }

      final count = await db.getStudentCount();
      final newState = StudentSyncState(
        count: count,
        lastSyncedAt: DateTime.now(),
        syncing: false,
      );
      state = AsyncData(newState);
      AppPubSub.publish(AppPubSubTopics.studentSynced, value: newState);
    } catch (e) {
      final current = state.asData?.value ?? const StudentSyncState();
      state = AsyncData(current.copyWith(
        syncing: false,
        error: e.toString(),
      ));
      AppPubSub.publish(AppPubSubTopics.globalSyncError, value: e.toString());
    }
  }
}

// Dashboard stats
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final db = ref.read(databaseProvider);
  return db.getUnpublishedCount();
});

class GlobalSyncState {
  final bool syncing;
  final String? error;
  final int? lastAttendanceSynced;
  final DateTime? lastSyncedAt;

  const GlobalSyncState({
    this.syncing = false,
    this.error,
    this.lastAttendanceSynced,
    this.lastSyncedAt,
  });

  GlobalSyncState copyWith({
    bool? syncing,
    String? error,
    int? lastAttendanceSynced,
    DateTime? lastSyncedAt,
  }) =>
      GlobalSyncState(
        syncing: syncing ?? this.syncing,
        error: error,
        lastAttendanceSynced: lastAttendanceSynced ?? this.lastAttendanceSynced,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

class GlobalSyncNotifier extends AsyncNotifier<GlobalSyncState> {
  @override
  Future<GlobalSyncState> build() async => const GlobalSyncState();

  Future<void> syncAll() async {
    final config = ref.read(configProvider).asData?.value;
    if (config == null || !config.isServerConfigured) return;

    state = AsyncData((state.asData?.value ?? const GlobalSyncState()).copyWith(
      syncing: true,
      error: null,
    ));

    try {
      // 1. Downstream Simplex: Pull Students
      await ref.read(studentSyncProvider.notifier).syncStudents();
      
      // 2. Upstream Simplex: Push Attendance
      final syncService = ref.read(syncServiceProvider);
      final count = await syncService.manualBulkSync(config);

      // Invalidate to refresh UI
      ref.invalidate(allStudentsProvider);
      ref.invalidate(recentRecordsProvider);
      ref.invalidate(pendingSyncCountProvider);

      final newState = GlobalSyncState(
        syncing: false,
        lastAttendanceSynced: count,
        lastSyncedAt: DateTime.now(),
      );
      state = AsyncData(newState);
      AppPubSub.publish(AppPubSubTopics.globalSynced, value: newState);
    } catch (e) {
      state = AsyncData((state.asData?.value ?? const GlobalSyncState()).copyWith(
        syncing: false,
        error: e.toString(),
      ));
      AppPubSub.publish(AppPubSubTopics.globalSyncError, value: e.toString());
    }
  }
}

final globalSyncProvider =
    AsyncNotifierProvider<GlobalSyncNotifier, GlobalSyncState>(
        GlobalSyncNotifier.new);


// ── Sijinak realtime runtime ────────────────────────────────────────────────

/// Lightweight TopicSubscriber that just calls a callback. Used to bridge
/// the bus's "incoming event" into a DeviceJobWorker tick without coupling
/// the worker to the bus.
class _JobCreatedSubscriber implements TopicSubscriber {
  final Future<void> Function() onCreated;
  _JobCreatedSubscriber(this.onCreated);

  @override
  List<String> get topics => const ['desktop.job.created'];

  @override
  Future<void> onEvent(String topic, dynamic data) => onCreated();
}

/// Long-lived controller that owns sijinak's realtime plumbing:
///   - the DeviceJobWorker (outbox executor)
///   - the DesktopSettingsStore (BE-canonical settings cache)
///   - the AbsensiInvalidationSubscriber (drops stale local locks)
///   - the single DesktopEventBus that fans WS frames out to all three
///
/// Recreated whenever the server URL / API key / hik MAC fingerprint changes.
class SijinakRuntimeController {
  final Ref ref;

  DeviceJobWorker? _worker;
  DesktopSettingsStore? _settingsStore;
  DesktopEventBus? _bus;
  CardOutboxWorker? _cardOutboxWorker;
  String? _activeFingerprint;

  SijinakRuntimeController(this.ref);

  DesktopSettingsStore? get settingsStore => _settingsStore;

  Future<void> ensureStarted(AppConfig config) async {
    if (!config.isServerConfigured) return;
    final fingerprint = '${config.serverUrl}|${config.apiKey}|${config.hikvisionMac}';
    if (_activeFingerprint == fingerprint && _worker != null) return;

    await _shutdown();
    _activeFingerprint = fingerprint;

    final api = ApiClient.fromConfig(config);
    final db = ref.read(databaseProvider);
    final worker = _buildWorker(config, api, db);
    final settingsStore = DesktopSettingsStore(api: api);
    final invalidator = AbsensiInvalidationSubscriber(db: db);
    final deletedSubscriber = StudentDeletedSubscriber(db: db);
    final cardOutboxWorker = CardOutboxWorker(db: db, api: api);
    final bus = _buildBus(config, worker, settingsStore, invalidator, deletedSubscriber);

    _worker = worker;
    _settingsStore = settingsStore;
    _bus = bus;
    _cardOutboxWorker = cardOutboxWorker;

    await worker.start();
    await settingsStore.refreshFromServer();
    await cardOutboxWorker.start();
    await bus.start();
  }

  Future<void> tickNow() async {
    await _worker?.tick();
  }

  /// Fire an immediate CardOutbox pass — called after enqueueing a fresh
  /// optimistic edit so the user sees the badge advance without waiting
  /// for the next periodic tick.
  Future<void> tickCardOutbox() async {
    await _cardOutboxWorker?.tick();
  }

  DeviceJobWorker _buildWorker(AppConfig config, BackendApiPort api, AppDatabase db) {
    final hik = IsapiClient(
      baseUrl: config.hikvisionBaseUrl,
      username: config.hikvisionUser,
      password: config.hikvisionPassword,
    );
    final worker = DeviceJobWorker(api: api, deviceId: _deviceIdFor(config));
    worker.register(HikCardSyncHandler(hik: hik, db: db));
    worker.register(HikPersonDeleteHandler(hik: hik));
    return worker;
  }

  DesktopEventBus _buildBus(
    AppConfig config,
    DeviceJobWorker worker,
    DesktopSettingsStore settingsStore,
    AbsensiInvalidationSubscriber invalidator,
    StudentDeletedSubscriber deletedSubscriber,
  ) {
    final bus = DesktopEventBus(baseUrl: config.serverUrl, apiKey: config.apiKey);
    bus.register(_JobCreatedSubscriber(worker.tick));
    bus.register(settingsStore);
    bus.register(invalidator);
    bus.register(deletedSubscriber);
    return bus;
  }

  Future<void> _shutdown() async {
    await _worker?.stop();
    await _cardOutboxWorker?.stop();
    await _bus?.close();
    _settingsStore?.dispose();
    _worker = null;
    _cardOutboxWorker = null;
    _bus = null;
    _settingsStore = null;
    _activeFingerprint = null;
  }

  String _deviceIdFor(AppConfig config) {
    final mac = config.hikvisionMac.trim();
    return mac.isEmpty ? 'sijinak-${config.serverUrl.hashCode}' : 'sijinak-$mac';
  }
}

final sijinakRuntimeProvider = Provider<SijinakRuntimeController>((ref) {
  final controller = SijinakRuntimeController(ref);
  ref.onDispose(controller._shutdown);
  return controller;
});

/// Back-compat alias for callers that previously referenced the worker
/// controller directly (e.g. UI hooks that nudge the worker after an
/// optimistic action). They only need `tickNow()`.
@Deprecated('Use sijinakRuntimeProvider')
final deviceJobWorkerControllerProvider = sijinakRuntimeProvider;

