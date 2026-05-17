import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/hikvision/isapi_client.dart';
import '../../data/local/database.dart';

/// Drains pending sijinak → Hikvision device writes.
///
/// Unlike CardOutboxWorker (BE-bound, has a dead-letter limit because BE may
/// legitimately reject a write), this worker retries **forever** — Hik is the
/// local LAN device and there's no scenario where giving up is correct.
/// Stuck rows surface in the UI; the operator can power-cycle the device.
class HikSyncWorker {
  static const Duration tickInterval = Duration(seconds: 5);
  static const int _backoffBaseSec = 5;
  static const int _backoffCapSec = 300;

  final HikOutboxPort outbox;
  final HikvisionDevicePort hik;

  Timer? _timer;
  bool _ticking = false;
  bool _started = false;

  HikSyncWorker({required this.outbox, required this.hik});

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(tickInterval, (_) => unawaited(tick()));
    await tick();
  }

  Future<void> stop() async {
    _started = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Public tick — also called immediately after an enqueue so the operator
  /// sees the badge advance without waiting for the periodic timer.
  Future<void> tick() async {
    if (_ticking) return;
    _ticking = true;
    try {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final due = await outbox.dueHikOutboxRows(nowSec: now);
      for (final row in due) {
        await _processOne(row);
      }
    } catch (e) {
      debugPrint('[HikSyncWorker] tick failed: $e');
    } finally {
      _ticking = false;
    }
  }

  Future<void> _processOne(HikOutboxData row) async {
    try {
      await _dispatch(row);
      await outbox.markHikOutboxDone(row.id);
    } catch (e) {
      await _scheduleRetry(row, e);
    }
  }

  Future<void> _dispatch(HikOutboxData row) async {
    switch (row.operation) {
      case HikOpType.upsertCard:
        await _upsertCard(row);
        return;
      case HikOpType.deleteCard:
        await _deleteCard(row);
        return;
      case HikOpType.deletePerson:
        await hik.deletePerson(employeeNo: row.employeeNo);
        return;
      default:
        throw StateError('Unknown HikOutbox.operation: ${row.operation}');
    }
  }

  Future<void> _upsertCard(HikOutboxData row) async {
    final newRfid = row.newRfid;
    if (newRfid == null || newRfid.isEmpty) {
      // Defensive: enqueue guard should have stopped this; treat as success.
      return;
    }
    final personName = (row.name?.isNotEmpty ?? false) ? row.name! : row.employeeNo;
    await hik.upsertPerson(employeeNo: row.employeeNo, name: personName);
    // Drop the old card binding first if we're replacing.
    final oldRfid = row.oldRfid;
    if (oldRfid != null && oldRfid.isNotEmpty && oldRfid != newRfid) {
      try {
        await hik.deleteCard(rfidNumber: oldRfid);
      } catch (_) {
        // Old card may already be gone or never have existed on device;
        // don't fail the whole op for that.
      }
    }
    await hik.upsertCard(rfidNumber: newRfid, employeeNo: row.employeeNo);
  }

  Future<void> _deleteCard(HikOutboxData row) async {
    final oldRfid = row.oldRfid;
    if (oldRfid != null && oldRfid.isNotEmpty) {
      try {
        await hik.deleteCard(rfidNumber: oldRfid);
      } catch (_) {
        // Card might already be off the device; we still want to drop the
        // person record.
      }
    }
    // No card = no purpose on the device.
    try {
      await hik.deletePerson(employeeNo: row.employeeNo);
    } catch (_) {
      // Person might already be gone (snapshot delete + clear card race).
    }
  }

  Future<void> _scheduleRetry(HikOutboxData row, Object error) async {
    final nextAttempt = row.attempts + 1;
    final delaySec = math.min(
      _backoffBaseSec * (1 << (nextAttempt - 1).clamp(0, 6)),
      _backoffCapSec,
    );
    final nextAt =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) + delaySec;
    await outbox.bumpHikOutboxRetry(
      id: row.id,
      attempts: nextAttempt,
      nextAttemptAt: nextAt,
      error: error.toString(),
    );
    debugPrint(
      '[HikSyncWorker] retry ${row.id} op=${row.operation} '
      'attempt=$nextAttempt nextIn=${delaySec}s err=$error',
    );
  }
}
