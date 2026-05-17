import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xls;
import 'package:path/path.dart' as p;
import '../../data/local/database.dart';
import '../../data/remote/api_client.dart';
import '../../providers/providers.dart';
import '../../services/app_pubsub.dart';
import '../../services/server_service.dart';
import '../../services/hik_outbox/hik_reconcile_service.dart';
import '../widgets/card_scan_dialog.dart';
import '../widgets/bulk_card_assign_dialog.dart';
import '../widgets/hik_reconcile_dialog.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  List<Student> _students = [];
  List<Student> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  bool _backendReady = false;
  Timer? _backendProbeTimer;
  DateTime? _lastBackendProbeAt;

  @override
  void initState() {
    super.initState();
    AppPubSub.subscribe(
      key: AppPubSubTopics.studentSynced,
      context: this,
      handler: (_, _) => _loadStudents(),
    );
    AppPubSub.subscribe(
      key: AppPubSubTopics.globalSynced,
      context: this,
      handler: (_, _) => _loadStudents(),
    );
    _loadStudents();
    _searchCtrl.addListener(_applyFilter);
    unawaited(_probeBackendReady(force: true));
    _backendProbeTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_probeBackendReady()),
    );
  }

  @override
  void dispose() {
    _backendProbeTimer?.cancel();
    AppPubSub.unsubscribe(context: this);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final students = await ref.read(studentServiceProvider).loadStudents();
    if (mounted) {
      setState(() {
        _students = students;
        _loading = false;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _students;
      } else {
        _filtered = _students.where((s) {
          return s.nama.toLowerCase().contains(q) ||
              (s.nisn?.toLowerCase().contains(q) ?? false) ||
              (s.kelas?.toLowerCase().contains(q) ?? false) ||
              (s.rfidNumber?.toLowerCase().contains(q) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _syncAndReload() async {
    setState(() => _loading = true);
    await ref.read(studentSyncProvider.notifier).syncStudents();
    await _loadStudents();
  }

  void _showCardOptions(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Kartu ${student.rfidNumber}'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _replaceCard(student);
            },
            child: const ListTile(
              leading: Icon(Icons.swap_horiz),
              title: Text('Ganti Kartu'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCard(student);
            },
            child: const ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Hapus Kartu', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(Student student) async {
    if (!await _ensureServerReady()) return;
    final config = ref.read(configProvider).asData?.value;
    if (config == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kartu'),
        content: Text('Hapus kartu "${student.rfidNumber}" dari ${student.nama}?\nKartu juga akan dihapus dari Hikvision (otomatis di belakang layar).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _applyCardChange(
      student: student,
      newRfidNumber: null,
      successMessage: 'Permintaan hapus kartu diantrekan (server akan konfirmasi)',
      failurePrefix: 'Gagal hapus kartu',
    );
  }

  Future<void> _replaceCard(Student student) async {
    if (!await _ensureServerReady()) return;
    final config = ref.read(configProvider).asData?.value;
    if (config == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Kartu'),
        content: Text(
          'Kartu "${student.rfidNumber}" akan diganti.\n'
          'Tap kartu baru pada reader.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final newCardNo = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CardScanDialog(),
    );
    if (newCardNo == null || !mounted) return;

    if (!await _confirmReassignIfOwned(newCardNo, student)) return;

    await _applyCardChange(
      student: student,
      newRfidNumber: newCardNo,
      successMessage: 'Penggantian kartu ke $newCardNo diantrekan',
      failurePrefix: 'Gagal ganti kartu',
    );
  }

  /// Card assign — BE first, sijinak DeviceJob worker pushes to Hikvision.
  /// Only callable when student.rfidNumber == null (button hidden otherwise).
  Future<void> _assignCard(Student student) async {
    if (!await _ensureServerReady()) return;
    final config = ref.read(configProvider).asData?.value;
    if (config == null) return;
    if (!mounted) return;

    final rfidNumber = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CardScanDialog(),
    );
    if (rfidNumber == null || !mounted) return;

    if (!await _confirmReassignIfOwned(rfidNumber, student)) return;

    await _applyCardChange(
      student: student,
      newRfidNumber: rfidNumber,
      successMessage: 'Kartu $rfidNumber diantrekan untuk ${student.nama}',
      failurePrefix: 'Gagal assign kartu',
    );
  }

  /// Single canonical path for any card mutation (assign / replace / remove).
  /// Calls BE's unified /card endpoint, mirrors the new value into Drift
  /// optimistically, then nudges the DeviceJob worker so the Hikvision push
  /// happens immediately instead of waiting for the next poll.
  /// Optimistic card edit. Writes local Drift + enqueues a CardOutbox row.
  /// The background CardOutboxWorker drains the row, calling BE. On BE
  /// rejection or exhausted retries the worker reverts Students.rfidNumber
  /// back to [student.rfidNumber] — BE remains ground truth.
  Future<void> _applyCardChange({
    required Student student,
    required String? newRfidNumber,
    required String successMessage,
    required String failurePrefix,
  }) async {
    final config = ref.read(configProvider).asData?.value;
    if (config == null) return;

    try {
      final db = ref.read(databaseProvider);
      await db.enqueueCardWrite(
        userId: student.userId,
        oldRfid: student.rfidNumber,
        newRfid: _normalizeRfid(newRfidNumber),
      );
      await _mirrorLocalCard(student.userId, newRfidNumber);
      await db.setStudentCardSyncStatus(student.userId, 'pending');
      _showSnack(successMessage);
      await _loadStudents();
      unawaited(ref.read(sijinakRuntimeProvider).tickCardOutbox());
    } catch (e) {
      _showSnack('$failurePrefix: $e');
    }
  }

  String? _normalizeRfid(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Looks up the scanned card in local Drift. If a *different* student
  /// already owns it, prompts the admin to either reassign (BE will move the
  /// card) or cancel. Returns true if the caller should proceed.
  Future<bool> _confirmReassignIfOwned(
    String rfidNumber,
    Student target,
  ) async {
    final db = ref.read(databaseProvider);
    final existing = await db.getStudentByCard(rfidNumber);
    if (existing == null) return true;
    if (existing.userId == target.userId) return true;
    if (!mounted) return false;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
        title: const Text('Kartu sudah terdaftar'),
        content: Text(
          'Kartu $rfidNumber sedang dipakai oleh:\n'
          '  • ${existing.nama}'
          '${existing.nisn != null ? ' (NISN ${existing.nisn})' : ''}\n\n'
          'Lanjut akan memindahkan kartu ke ${target.nama}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pindahkan'),
          ),
        ],
      ),
    );
    return go == true;
  }

  Future<void> _mirrorLocalCard(String userId, String? newRfidNumber) async {
    final db = ref.read(databaseProvider);
    final normalized = _normalizeRfid(newRfidNumber);
    if (normalized == null) {
      await db.removeCardFromStudent(userId);
      return;
    }
    await db.assignCardToStudent(userId, normalized);
  }

  /// Explicit reconcile flow:
  ///   1. Build plan (read device + diff against local).
  ///   2. Show preview dialog with counts + sample reasons.
  ///   3. On confirm, enqueue every entry into HikOutbox + tick worker.
  ///
  /// Pure side-effect: device converges toward local DB state. Never the
  /// other way around.
  Future<void> _runHikReconcile() async {
    final service = ref.read(hikReconcileServiceProvider);
    if (service == null) {
      _showSnack('Hikvision belum dikonfigurasi di Settings');
      return;
    }

    HikReconcilePlan plan;
    try {
      plan = await _buildPlanWithLoader(service);
    } catch (e) {
      _showSnack('Gagal membaca device: $e');
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => HikReconcileDialog(plan: plan),
    );
    if (confirmed != true || !mounted) return;
    if (plan.isEmpty) return;

    final enqueued = await service.enqueuePlan(plan);
    unawaited(ref.read(sijinakRuntimeProvider).tickHikOutbox());
    _showSnack('$enqueued perubahan diantrekan ke Hik');
  }

  Future<HikReconcilePlan> _buildPlanWithLoader(HikReconcileService service) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Membaca state Hikvision...'),
              ],
            ),
          ),
        ),
      ),
    );
    return service.buildPlan().whenComplete(() {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  Future<void> _importCardsCsv() async {
    if (!await _ensureServerReady()) return;
    final config = ref.read(configProvider).asData?.value;
    if (config == null) return;

    final proceed = await _showImportInstructionDialog();
    if (proceed != true || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      dialogTitle: 'Pilih file CSV/XLSX (header: nis, rfid_number)',
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    try {
      final rows = await _parseImportRows(filePath);
      if (rows.isEmpty) {
        _showSnack('Tidak ada data valid dalam file');
        return;
      }
      if (!mounted) return;
      final api = ApiClient.fromConfig(config);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            BulkCardAssignDialog(rows: rows, config: config, api: api),
      );
      await _loadStudents();
    } catch (e) {
      _showSnack('Gagal membaca file: $e');
    }
  }

  Future<List<Map<String, String>>> _parseImportRows(String filePath) async {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.xlsx') return _parseXlsxRows(filePath);
    return _parseCsvRows(filePath);
  }

  Future<List<Map<String, String>>> _parseCsvRows(String filePath) async {
    final content = await File(filePath).readAsString();
    final lines = content
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) throw Exception('File CSV kosong atau hanya header');

    final header =
        lines.first.split(',').map((h) => h.trim().toLowerCase()).toList();
    final nisIdx = _findNisIndex(header);
    final cardIdx = _findCardNumberIndex(header);
    if (nisIdx < 0 || cardIdx < 0) {
      throw Exception('Header harus mengandung kolom: nisn dan rfid_number');
    }

    final rows = <Map<String, String>>[];
    for (int i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',').map((c) => c.trim()).toList();
      if (cols.length <= nisIdx || cols.length <= cardIdx) continue;
      final nisn = cols[nisIdx];
      final rfidNumber = cols[cardIdx];
      if (nisn.isEmpty || rfidNumber.isEmpty) continue;
      rows.add({'nisn': nisn, 'rfidNumber': rfidNumber});
    }
    return rows;
  }

  Future<List<Map<String, String>>> _parseXlsxRows(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = xls.Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) throw Exception('File XLSX tidak memiliki sheet');

    final sheet = excel.tables.values.first;
    final allRows = sheet.rows;
    if (allRows.length < 2) throw Exception('File XLSX kosong atau hanya header');

    final header =
        allRows.first.map((cell) => _cellText(cell).toLowerCase()).toList();
    final nisIdx = _findNisIndex(header);
    final cardIdx = _findCardNumberIndex(header);
    if (nisIdx < 0 || cardIdx < 0) {
      throw Exception('Header harus mengandung kolom: nisn dan rfid_number');
    }

    final rows = <Map<String, String>>[];
    for (int i = 1; i < allRows.length; i++) {
      final row = allRows[i];
      if (row.length <= nisIdx || row.length <= cardIdx) continue;
      final nisn = _normalizeNumericLike(_cellText(row[nisIdx]));
      final rfidNumber = _normalizeNumericLike(_cellText(row[cardIdx]));
      if (nisn.isEmpty || rfidNumber.isEmpty) continue;
      rows.add({'nisn': nisn, 'rfidNumber': rfidNumber});
    }
    return rows;
  }

  int _findNisIndex(List<String> header) =>
      header.indexWhere((h) => h == 'nisn' || h == 'nis');

  int _findCardNumberIndex(List<String> header) => header.indexWhere(
        (h) =>
            h == 'rfid_number' ||
            h == 'rfidnumber' ||
            h == 'card_number' ||
            h == 'cardno' ||
            h == 'card_no' ||
            h == 'card number' ||
            h == 'cardid' ||
            h == 'card_id',
      );

  String _cellText(dynamic cell) {
    final rawValue = cell?.value;
    if (rawValue == null) return '';
    var text = rawValue.toString().trim();
    final wrapped = RegExp(r'^[A-Za-z]+CellValue\((.*)\)$').firstMatch(text);
    if (wrapped != null) text = wrapped.group(1)?.trim() ?? '';
    if (text.startsWith('value:')) text = text.substring(6).trim();
    if ((text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'"))) {
      text = text.substring(1, text.length - 1).trim();
    }
    return text;
  }

  String _normalizeNumericLike(String value) {
    final v = value.trim();
    return v.endsWith('.0') ? v.substring(0, v.length - 2) : v;
  }

  Future<bool?> _showImportInstructionDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Instruksi Import Kartu'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Format file CSV/XLSX dengan header:'),
                SizedBox(height: 6),
                Text('1. nis'),
                Text('2. rfid_number'),
                SizedBox(height: 8),
                SizedBox(height: 8),
                Text(
                  'Contoh isi file:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'nis,rfid_number\n'
                  '2425001,A1B2C3D4\n'
                  '2425002,E5F6G7H8',
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
                SizedBox(height: 8),
                Text(
                  'Hanya siswa tanpa kartu yang akan diproses.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Lanjut Pilih File'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _probeBackendReady({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastBackendProbeAt != null) {
      if (now.difference(_lastBackendProbeAt!) < const Duration(seconds: 3)) {
        return;
      }
    }
    final config = ref.read(configProvider).asData?.value;
    if (config == null || !config.isServerConfigured) {
      _lastBackendProbeAt = now;
      if (mounted && _backendReady) setState(() => _backendReady = false);
      return;
    }
    final result =
        await ServerService.testConnection(config.serverUrl, config.apiKey);
    _lastBackendProbeAt = DateTime.now();
    if (!mounted) return;
    if (_backendReady != result.success) {
      setState(() => _backendReady = result.success);
    }
  }

  // Only requires server — Hikvision is optional for card assign.
  Future<bool> _ensureServerReady() async {
    final config = ref.read(configProvider).asData?.value;
    if (config == null || !config.isServerConfigured) {
      _showSnack('Konfigurasi server belum lengkap');
      return false;
    }
    final result =
        await ServerService.testConnection(config.serverUrl, config.apiKey);
    if (!mounted) return false;
    if (_backendReady != result.success) {
      setState(() => _backendReady = result.success);
    }
    if (!result.success) {
      _showSnack('Tidak dapat terhubung ke server');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final syncState = ref.watch(studentSyncProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant, width: 1),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: colors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Daftar Siswa',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_filtered.length} siswa',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.outline),
                  ),
                  const SizedBox(width: 8),
                  // Server status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_backendReady ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _backendReady ? 'Server OK' : 'Server OFF',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _backendReady
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _runHikReconcile,
                    icon: const Icon(Icons.dvr_outlined, size: 18),
                    label: const Text('Sync ke Hik'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _importCardsCsv,
                    icon: const Icon(Icons.file_upload_outlined, size: 18),
                    label: const Text('Import kartu'),
                  ),
                  const SizedBox(width: 4),
                  syncState.when(
                    data: (s) => s.syncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.sync, size: 20),
                            tooltip: 'Sinkronisasi dari server',
                            onPressed: _syncAndReload,
                          ),
                    loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, _) => IconButton(
                      icon: const Icon(Icons.sync_problem,
                          size: 20, color: Colors.red),
                      onPressed: _syncAndReload,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama, NIS, kelas, nomor kartu...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                ),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off,
                              size: 56, color: colors.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            _students.isEmpty
                                ? 'Belum ada data siswa'
                                : 'Tidak ditemukan',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(color: colors.outline),
                          ),
                          if (_students.isEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Input siswa melalui website admin, lalu sinkronisasi',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colors.outlineVariant),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final s = _filtered[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color:
                                  colors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.primaryContainer
                                  .withValues(alpha: 0.5),
                              child: Text(
                                s.nama.isNotEmpty
                                    ? s.nama[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(
                              s.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              [
                                if (s.nisn != null) 'NISN: ${s.nisn}',
                                if (s.kelas != null) s.kelas,
                              ].join(' · '),
                              style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 12),
                            ),
                            trailing: s.rfidNumber != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _CardSyncDot(status: s.cardSyncStatus),
                                      const SizedBox(width: 6),
                                      Chip(
                                        label: Text(
                                          s.rfidNumber!,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        avatar: Icon(
                                          s.hikRegistered
                                              ? Icons.contactless
                                              : Icons.contactless_outlined,
                                          size: 14,
                                          color: s.hikRegistered
                                              ? colors.primary
                                              : colors.outline,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        deleteIcon: const Icon(Icons.more_horiz, size: 14),
                                        onDeleted: () => _showCardOptions(s),
                                      ),
                                    ],
                                  )
                                : IconButton(
                                    icon: Icon(Icons.add_card,
                                        color: colors.primary),
                                    tooltip: 'Daftarkan kartu RFID',
                                    onPressed: () => _assignCard(s),
                                  ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}


/// 8px colored dot reflecting [Student.cardSyncStatus]:
///   green  = synced (BE confirmed)
///   amber  = pending (queued in CardOutbox, worker processing)
///   red    = failed (retries exhausted / BE rejected; local reverted)
class _CardSyncDot extends StatelessWidget {
  final String status;
  const _CardSyncDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = _colorFor(status, Theme.of(context).colorScheme);
    return Tooltip(
      message: _tooltipFor(status),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: scheme,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Color _colorFor(String status, ColorScheme colors) {
    if (status == 'pending') return Colors.amber.shade600;
    if (status == 'failed') return colors.error;
    return Colors.green.shade600;
  }

  String _tooltipFor(String status) {
    if (status == 'pending') return 'Kartu sedang disinkronisasi ke server';
    if (status == 'failed') return 'Sinkronisasi kartu gagal — coba lagi';
    return 'Kartu sinkron dengan server';
  }
}
