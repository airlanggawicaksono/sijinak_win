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
  /// Max attempts before we give up and revert local state to the snapshot
  /// taken at enqueue time.
  static const int maxAttempts = 8;

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
    await _enqueueHikSideEffect(row);
    final cb = onBackendAck;
    if (cb != null) await cb();
  }

  /// BE confirmed the canonical card change. Mirror that change to the local
  /// Hik device via the HikOutbox. Worker filters out no-op transitions
  /// (null → null) inside `enqueueHikWrite`.
  Future<void> _enqueueHikSideEffect(CardOutboxData row) async {
    final newRfid = row.newRfid;
    final oldRfid = row.oldRfid;
    final hasNew = newRfid != null && newRfid.isNotEmpty;
    final hasOld = oldRfid != null && oldRfid.isNotEmpty;

    final operation = hasNew ? HikOpType.upsertCard : HikOpType.deleteCard;
    if (operation == HikOpType.deleteCard && !hasOld) return;

    final student = await db.getStudentByUserId(row.userId);
    await db.enqueueHikWrite(
      userId: row.userId,
      employeeNo: hikvisionEmployeeNoFor(row.userId),
      operation: operation,
      name: student?.nama,
      oldRfid: oldRfid,
      newRfid: newRfid,
    );
  }

  Future<void> _handleApiError(CardOutboxData row, ApiException e) async {
    if (_isTerminalStatus(e.statusCode)) {
      await _revertAndDie(row, 'BE ${e.statusCode}: ${e.message}');
      return;
    }
    await _scheduleRetry(row, '${e.statusCode}: ${e.message}');
  }

  Future<void> _handleTransientError(CardOutboxData row, Object e) async {
    await _scheduleRetry(row, e.toString());
  }

  bool _isTerminalStatus(int code) {
    if (code == 401 || code == 403) return true;
    if (code == 404) return true;
    if (code == 409) return true;
    if (code >= 400 && code < 500) return true;
    return false;
  }

  Future<void> _scheduleRetry(CardOutboxData row, String error) async {
    final nextAttempts = row.attempts + 1;
    if (nextAttempts >= maxAttempts) {
      await _revertAndDie(row, 'exhausted retries: $error');
      return;
    }
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
    // No Hik undo needed: Hik writes only fire from _markSuccess, so a
    // revert path means we never touched the device for this row.
    debugPrint(
      '[CardOutboxWorker] reverted ${row.userId} → ${row.oldRfid} ($error)',
    );
  }

  int _backoffSeconds(int attempt) {
    final raw = 5 * (1 << (attempt - 1));
    return raw > 300 ? 300 : raw;
  }

  int _nowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
}
