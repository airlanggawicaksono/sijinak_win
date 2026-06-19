import 'dart:async';
import 'dart:collection';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../data/hikvision/hik_event.dart';
import '../../data/local/database.dart';
import '../../data/remote/dto/izin_dispatch_request_dto.dart';
import '../../providers/providers.dart';
import '../../services/network_discovery_service.dart';
import '../../services/izin_payload.dart';
import '../../services/ticket_printer_service.dart';
import '../widgets/tap_popup.dart';
import 'dashboard.dart';
import 'students_screen.dart';
import 'absensi_screen.dart';

class _AttendanceLabel {
  final String label;
  final Color color;
  const _AttendanceLabel({required this.label, required this.color});
}

class _IzinEntry {
  final HikEvent event;
  final Student student;
  _IzinEntry(this.event, this.student);
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;
  DateTime? _lastNavTriggeredSyncAt;
  bool _navigating = false;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outlined),
      selectedIcon: Icon(Icons.people),
      label: Text('Siswa'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.fact_check_outlined),
      selectedIcon: Icon(Icons.fact_check),
      label: Text('Absensi'),
    ),
  ];

  bool _hikStarted = false;
  bool _hikStarting = false;
  String? _startedConfigFingerprint;
  Timer? _syncTimer;
  bool _syncRunning = false;
  final Set<String> _inProgress = {};
  bool _popupShowing = false;
  final Queue<_IzinEntry> _izinQueue = Queue();

  void _ensureServicesStarted({bool force = false}) {
    final config = ref.read(configProvider).asData?.value;
    if (config == null) return;

    unawaited(ref.read(sijinakRuntimeProvider).ensureStarted(config));

    final fingerprint =
        '${config.hikvisionIp}|${config.hikvisionUser}|${config.hikvisionPassword}|${config.hikvisionMac}';
    if (!force && _hikStarted && _startedConfigFingerprint == fingerprint) {
      return;
    }
    if (_hikStarting || !config.isHikvisionConfigured) return;

    _hikStarting = true;
    unawaited(_startHikvisionWithAutoDetect(config));
  }

  Future<void> _startHikvisionWithAutoDetect(AppConfig initialConfig) async {
    var config = initialConfig;

    try {
      final hasManualIp = config.hikvisionIp.trim().isNotEmpty;
      final mac = config.hikvisionMac.trim();
      if (!hasManualIp && mac.isNotEmpty) {
        final detectedIp = await NetworkDiscoveryService.findIpByMac(mac);
        if (detectedIp != null && detectedIp != config.hikvisionIp) {
          final updatedConfig = AppConfig(
            hikvisionIp: detectedIp,
            hikvisionUser: config.hikvisionUser,
            hikvisionPassword: config.hikvisionPassword,
            hikvisionMac: config.hikvisionMac,
            serverUrl: config.serverUrl,
            apiKey: config.apiKey,
            wablasBaseUrl: config.wablasBaseUrl,
            wablasApiKey: config.wablasApiKey,
            wablasSecKey: config.wablasSecKey,
            thermalPrinterKey: config.thermalPrinterKey,
            thermalPrinterName: config.thermalPrinterName,
          );
          await ref.read(configProvider.notifier).updateConfig(updatedConfig);
          config = updatedConfig;
        }
      }

      ref.read(hikvisionServiceProvider).start(config);
      final attendance = ref.read(attendanceServiceProvider);
      attendance.onAutoAttendance = _onAutoAttendance;
      attendance.onIzinRequired = _onIzinRequired;
      attendance.onAlreadySignedOff = _onAlreadySignedOff;
      attendance.start();

      _hikStarted = true;
      _startedConfigFingerprint =
          '${config.hikvisionIp}|${config.hikvisionUser}|${config.hikvisionPassword}|${config.hikvisionMac}';
    } finally {
      _hikStarting = false;
    }
  }

  // ── Auto masuk/keluar (no popup) ─────────────────────────────────────────

  void _onAutoAttendance(HikEvent event, Student student, String eventType) {
    final key = student.rfidNumber ?? event.rfidNumber;
    if (_inProgress.contains(key)) return;
    _inProgress.add(key);
    unawaited(_saveAutoRecord(event, student, eventType));
  }

  Future<void> _saveAutoRecord(
    HikEvent event,
    Student student,
    String eventType,
  ) async {
    final key = student.rfidNumber ?? event.rfidNumber;
    try {
      final db = ref.read(databaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final recordId = '${student.userId}_${event.rfidNumber}_${event.serialNo}';

      await db.into(db.tapRecords).insert(
        TapRecordsCompanion(
          id: Value(recordId),
          rfidNumber: Value(event.rfidNumber),
          eventType: Value(eventType),
          deviceTime: Value(event.dateTime.millisecondsSinceEpoch ~/ 1000),
          hikSerialNo: Value(event.serialNo),
          createdAt: Value(now),
          reason: const Value(null),
          publishedAt: const Value(null),
        ),
        mode: InsertMode.insertOrReplace,
      );

      ref.invalidate(recentRecordsProvider);
      ref.invalidate(pendingSyncCountProvider);
      unawaited(_syncInBackground());

      if (mounted) {
        _showAttendanceSnack(student, eventType, event.dateTime);
      }
    } finally {
      _inProgress.remove(key);
    }
  }

  /// Snackbar shown after a successful `absen_masuk` or `absen_keluar` tap.
  /// For absen_masuk we additionally classify locally against the BE-pushed
  /// `late_cutoff_time` so the user sees TERLAMBAT immediately, before the
  /// BE replies.
  void _showAttendanceSnack(Student student, String eventType, DateTime deviceTime) {
    final classification = _classifyAttendance(eventType, deviceTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${student.nama} — ${classification.label}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: classification.color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  _AttendanceLabel _classifyAttendance(String eventType, DateTime deviceTime) {
    if (eventType == 'absen_keluar') {
      return const _AttendanceLabel(label: 'KELUAR', color: Colors.blue);
    }
    final settings = ref.read(sijinakRuntimeProvider).settingsStore?.current;
    if (settings != null && settings.isLateAt(deviceTime)) {
      return const _AttendanceLabel(label: 'MASUK — TERLAMBAT', color: Colors.orange);
    }
    return const _AttendanceLabel(label: 'MASUK', color: Colors.green);
  }

  // ── Already signed off alert ──────────────────────────────────────────────

  void _onAlreadySignedOff(Student student) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${student.nama} — Anda telah melakukan absensi keluar hari ini.',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Izin popup + ticket print ─────────────────────────────────────────────

  void _onIzinRequired(HikEvent event, Student student) {
    final key = student.rfidNumber ?? event.rfidNumber;
    if (_inProgress.contains(key)) return;
    _inProgress.add(key);
    _izinQueue.add(_IzinEntry(event, student));
    _maybeShowIzinPopup();
  }

  void _maybeShowIzinPopup() {
    if (_popupShowing || _izinQueue.isEmpty) return;
    final entry = _izinQueue.removeFirst();
    unawaited(_showIzinPopup(entry));
  }

  Future<void> _showIzinPopup(_IzinEntry entry) async {
    _popupShowing = true;
    try {
      final result = await showDialog<TapPopupResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TapPopupDialog(student: entry.student),
      );

      if (result != null && result.eventType == 'izin') {
        final printed = await _printIzinTicket(entry.student, result);
        if (printed) {
          await _saveIzinRecord(entry, result);
        }
      }
    } finally {
      _inProgress.remove(entry.student.rfidNumber ?? entry.event.rfidNumber);
      _popupShowing = false;
      _maybeShowIzinPopup();
    }
  }

  Future<void> _saveIzinRecord(_IzinEntry entry, TapPopupResult result) async {
    final db = ref.read(databaseProvider);
    final config = ref.read(configProvider).asData?.value;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final recordId =
        result.existingRecordId ??
        '${entry.student.userId}_${entry.event.rfidNumber}_${entry.event.serialNo}';

    await db.into(db.tapRecords).insert(
      TapRecordsCompanion(
        id: Value(recordId),
        rfidNumber: Value(entry.event.rfidNumber),
        eventType: const Value('izin'),
        deviceTime: Value(entry.event.dateTime.millisecondsSinceEpoch ~/ 1000),
        hikSerialNo: Value(entry.event.serialNo),
        createdAt: Value(now),
        reason: Value(encodeIzinReasonPayload(
          reason: result.reason,
          perkiraanKembali: result.estimatedReturnAt,
        )),
        publishedAt: const Value(null),
      ),
      mode: InsertMode.insertOrReplace,
    );

    if (config != null) {
      final dispatchResult = await ref.read(izinDispatchServiceProvider).dispatch(
            config: config,
            request: IzinDispatchRequestDTO(
              recordId: recordId,
              userId: entry.student.userId,
              deviceTime: entry.event.dateTime,
              reason: result.reason?.trim() ?? '',
              perkiraanKembali: result.estimatedReturnAt,
              studentName: entry.student.nama,
              nisn: entry.student.nisn,
            ),
          );

      if (dispatchResult.backendAccepted) {
        final publishedAt = (dispatchResult.backendPublishedAt ??
                DateTime.now())
            .millisecondsSinceEpoch ~/
            1000;
        await db.markPublished(recordId, publishedAt);
      }
    }

    ref.invalidate(recentRecordsProvider);
    ref.invalidate(pendingSyncCountProvider);
    unawaited(_syncInBackground());
  }

  Future<bool> _printIzinTicket(Student student, TapPopupResult result) async {
    final reason = result.reason?.trim();
    if (reason == null || reason.isEmpty) return false;
    final config = ref.read(configProvider).asData?.value;
    final preferredPrinterKey = config?.thermalPrinterKey;

    final printerReady = await ref
        .read(ticketPrinterServiceProvider)
        .isPrinterReady(preferredPrinterKey: preferredPrinterKey);
    if (!printerReady) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Printer thermal tidak terhubung. Proses izin dibatalkan.'),
        ),
      );
      return false;
    }

    final payload = IzinTicketPayload(
      studentName: student.nama,
      nisn: student.nisn,
      alasanIzin: reason,
      waktuKeluar: DateTime.now(),
      perkiraanKembali: result.estimatedReturnAt,
    );

    try {
      await ref.read(ticketPrinterServiceProvider).printIzinTicket(
        payload,
        copyNumber: 1,
        preferredPrinterKey: preferredPrinterKey,
      );
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cetak tiket gagal: $e')));
      return false;
    }

    if (!mounted) return false;
    final confirmSecondCopy = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cetak Ulang Salinan Kedua'),
        content: const Text('Copy pertama sudah tercetak. Lanjut cetak copy kedua?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cetak'),
          ),
        ],
      ),
    );

    if (confirmSecondCopy != true) return true;

    try {
      await ref.read(ticketPrinterServiceProvider).printIzinTicket(
        payload,
        copyNumber: 2,
        preferredPrinterKey: preferredPrinterKey,
      );
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Cetak copy kedua gagal: $e')));
    }
    return true;
  }

  // ── Sync loop ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _startAutoSyncLoop();
  }

  void _startAutoSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      unawaited(_syncInBackground());
    });
    unawaited(_syncInBackground());
  }

  Future<void> _syncInBackground() async {
    if (_syncRunning) return;
    final config = ref.read(configProvider).asData?.value;
    if (config == null || !config.isServerConfigured) return;

    _syncRunning = true;
    try {
      await ref.read(globalSyncProvider.notifier).syncAll();
    } catch (_) {
    } finally {
      _syncRunning = false;
    }
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;

    setState(() => _selectedIndex = index);
    setState(() => _navigating = true);
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _navigating = false);
    });

    if (index == 0 || index == 1) {
      final now = DateTime.now();
      final last = _lastNavTriggeredSyncAt;
      if (last == null || now.difference(last) >= const Duration(seconds: 10)) {
        _lastNavTriggeredSyncAt = now;
        unawaited(_syncInBackground());
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    ref.read(attendanceServiceProvider).stop();
    ref.read(hikvisionServiceProvider).stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(configProvider, (_, next) {
      final config = next.asData?.value;
      if (config != null) {
        _ensureServicesStarted(force: true);
      }
    });
    _ensureServicesStarted();

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
            backgroundColor: colors.surfaceContainerLow,
            indicatorColor: colors.primaryContainer,
          ),
          VerticalDivider(thickness: 1, width: 1, color: colors.outlineVariant),
          Expanded(
            child: Stack(
              children: [
                IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    DashboardScreen(),
                    StudentsScreen(),
                    AbsensiScreen(),
                  ],
                ),
                if (_navigating)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: ColoredBox(
                        color: colors.surface.withValues(alpha: 0.45),
                        child: const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
