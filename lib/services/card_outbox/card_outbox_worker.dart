import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/hikvision/isapi_client.dart';
import '../../data/local/database.dart';
import '../../data/remote/api_client.dart';

/// Drains queued [CardOutbox] rows by POSTing to BE. Provides the durability
/// + ground-truth-revert guarantees described in problem.md §6.1 follow-up.
///
/// Lifecycle owned by [SijinakRuntimeController]. One worker per runtime.
class CardOutboxWorker {
  /// Tick cadence — chosen short enough that retries feel responsive without
  /// hammering BE during sustained outages (exp backoff still gates per-row).
  static const Duration tickInterval = Duration(seconds: 5);

  final AppDatabase db;
  final BackendApiPort api;

  /// Fired after each successful or revert-triggering action so the HikSyncWorker
  /// can drain the row this enqueues on the same heartbeat instead of waiting
  /// for its periodic tick. Optional — runtime wires this to
  /// [HikSyncWorker.tick]; tests can leave it null.
  final Future<void> Function()? onBackendAck;

  Timer? _timer;
  bool _ticking = false;
  bool _started = false;

  CardOutboxWorker({
    required this.db,
    required this.api,
    this.onBackendAck,
  });

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

  /// Trigger an immediate pass — call after enqueueing a fresh edit so the
  /// user doesn't wait for the next tick.
  Future<void> tick() async {
    if (_ticking) return;
    _ticking = true;
    try {
      final now = _nowSec();
      final rows = await db.dueCardOutboxRows(nowSec: now);
      for (final row in rows) {
        await _processOne(row);
      }
    } catch (e) {
      debugPrint('[CardOutboxWorker] tick failed: $e');
    } finally {
      _ticking = false;
    }
  }

  // ── Per-row processing ──────────────────────────────────────────────

  Future<void> _processOne(CardOutboxData row) async {
    try {
      await api.setStudentCard(row.userId, row.newRfid);
      await _markSuccess(row);
    } on ApiException catch (e) {
      await _handleApiError(row, e);
    } catch (e) {
      await _handleTransientError(row, e);
    }
  }

  Future<void> _markSuccess(CardOutboxData row) async {
    await db.markCardOutboxDone(row.id);
    await db.setStudentCardSyncStatus(row.userId, 'synced');
    // Device write is NOT created here anymore — it was enqueued at edit time,
    // in parallel with this server-bound row (see db.enqueueCardChange). That
    // decoupling is what lets the LAN device update while the server is down.
    final cb = onBackendAck;
    if (cb != null) await cb();
  }

  Future<void> _handleApiError(CardOutboxData row, ApiException e) async {
    if (_isTerminalStatus(e.statusCode)) {
      // BE actively rejected (4xx). This is the only path that gives up —
      // server is reachable and says no, so revert local + undo on device.
      await _revertAndDie(row, 'BE ${e.statusCode}: ${e.message}');
      return;
    }
    // 5xx — server reachable but erroring. Don't lose the operator's edit;
    // keep retrying, stay 'pending'.
    await _scheduleRetry(row, '${e.statusCode}: ${e.message}');
  }

  Future<void> _handleTransientError(CardOutboxData row, Object e) async {
    // Network / timeout — server unreachable. Retry forever, stay 'pending'.
    // The card already lives on the device; this is just the server catching up.
    await _scheduleRetry(row, e.toString());
  }

  bool _isTerminalStatus(int code) {
    if (code == 401 || code == 403) return true;
    if (code == 404) return true;
    if (code == 409) return true;
    if (code >= 400 && code < 500) return true;
    return false;
  }

  /// Transient/5xx backoff. Never dead-letters — a server that is merely
  /// unreachable must not cost the operator their edit. The row stays 'queued'
  /// and the student stays 'pending' until the server confirms or 4xx-rejects.
  Future<void> _scheduleRetry(CardOutboxData row, String error) async {
    final nextAttempts = row.attempts + 1;
    final delay = _backoffSeconds(nextAttempts);
    await db.bumpCardOutboxRetry(
      id: row.id,
      attempts: nextAttempts,
      nextAttemptAt: _nowSec() + delay,
      error: error,
    );
    await db.setStudentCardSyncStatus(row.userId, 'pending');
  }

  Future<void> _revertAndDie(CardOutboxData row, String error) async {
    await db.markCardOutboxDead(row.id, error);
    await db.revertStudentCard(row.userId, row.oldRfid);
    // The device already applied this card at edit time (parallel write). BE
    // rejected it → push a compensating Hik write so the device matches BE.
    await _enqueueCompensatingHikWrite(row);
    debugPrint(
      '[CardOutboxWorker] reverted ${row.userId} → ${row.oldRfid} ($error)',
    );
  }

  /// Undo, on the device, a card edit that BE rejected. Restores the device to
  /// the pre-edit state captured in [row].oldRfid.
  Future<void> _enqueueCompensatingHikWrite(CardOutboxData row) async {
    final newRfid = row.newRfid;
    final oldRfid = row.oldRfid;
    final hasNew = newRfid != null && newRfid.isNotEmpty;
    final hasOld = oldRfid != null && oldRfid.isNotEmpty;
    if (!hasNew && !hasOld) return; // nothing ever hit the device

    final employeeNo = hikvisionEmployeeNoFor(row.userId);
    final student = await db.getStudentByUserId(row.userId);

    if (hasOld) {
      // Re-bind the old card; upsert drops the rejected new card in the same op.
      await db.enqueueHikWrite(
        userId: row.userId,
        employeeNo: employeeNo,
        operation: HikOpType.upsertCard,
        name: student?.nama,
        oldRfid: newRfid,
        newRfid: oldRfid,
      );
    } else {
      // Fresh assign rejected — strip the card (and person) off the device.
      await db.enqueueHikWrite(
        userId: row.userId,
        employeeNo: employeeNo,
        operation: HikOpType.deleteCard,
        oldRfid: newRfid,
      );
    }
    final cb = onBackendAck;
    if (cb != null) await cb(); // nudge HikSyncWorker to drain the undo now
  }

  int _backoffSeconds(int attempt) {
    // Clamp the shift: retries are now unbounded, so an unclamped `1 << n`
    // would overflow 64-bit and yield garbage (negative/zero) backoff.
    final raw = 5 * (1 << (attempt - 1).clamp(0, 6));
    return raw > 300 ? 300 : raw;
  }

  int _nowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
