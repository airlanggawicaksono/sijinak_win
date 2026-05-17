import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/remote/api_client.dart';
import '../../data/remote/dto/device_jobs/device_job_dto.dart';
import 'device_job_handler.dart';

/// Pulls outbox jobs from the backend, dispatches by [DeviceJobHandler.jobType],
/// and acks completion / failure.
///
/// Two trigger sources:
///   - Periodic poll (safety net, survives missed WS events).
///   - External tick (e.g. fired by the WS subscriber when a new job arrives).
///
/// Single-flight: overlapping ticks are coalesced so we never claim the same
/// job twice concurrently in this process.
class DeviceJobWorker {
  final BackendApiPort api;
  final String deviceId;
  final Map<String, DeviceJobHandler> _handlers = {};

  Timer? _pollTimer;
  bool _ticking = false;
  bool _started = false;

  DeviceJobWorker({required this.api, required this.deviceId});

  void register(DeviceJobHandler handler) {
    _handlers[handler.jobType] = handler;
  }

  List<String> get registeredTypes => _handlers.keys.toList();

  Future<void> start({Duration pollInterval = const Duration(seconds: 30)}) async {
    if (_started) return;
    _started = true;
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(tick()));
    await tick();
  }

  Future<void> stop() async {
    _started = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Manually trigger a tick. Called by the WS subscriber on push events.
  Future<void> tick() async {
    if (_ticking) return;
    if (_handlers.isEmpty) return;
    _ticking = true;
    try {
      final pending = await _fetchPending();
      for (final job in pending) {
        await _runOne(job);
      }
    } catch (e) {
      debugPrint('[DeviceJobWorker] tick failed: $e');
    } finally {
      _ticking = false;
    }
  }

  Future<List<DeviceJobDTO>> _fetchPending() {
    return api.listPendingJobs(types: registeredTypes);
  }

  Future<void> _runOne(DeviceJobDTO job) async {
    final handler = _handlers[job.jobType];
    if (handler == null) return;

    final claim = await _claimSafely(job.id);
    if (!claim.claimed || claim.job == null) return;

    await _executeAndAck(handler, claim.job!);
  }

  Future<ClaimResponseDTO> _claimSafely(String jobId) async {
    try {
      return await api.claimJob(jobId: jobId, deviceId: deviceId);
    } catch (e) {
      debugPrint('[DeviceJobWorker] claim $jobId failed: $e');
      return const ClaimResponseDTO(claimed: false);
    }
  }

  Future<void> _executeAndAck(DeviceJobHandler handler, DeviceJobDTO job) async {
    final payload = DeviceJobPayload(
      jobId: job.id,
      jobType: job.jobType,
      data: job.payload,
    );
    try {
      await handler.execute(payload);
      await api.completeJob(jobId: job.id, deviceId: deviceId);
    } catch (e) {
      debugPrint('[DeviceJobWorker] job ${job.id} (${job.jobType}) failed: $e');
      await _reportFailure(job.id, e);
    }
  }

  Future<void> _reportFailure(String jobId, Object error) async {
    try {
      await api.failJob(jobId: jobId, deviceId: deviceId, error: error.toString());
    } catch (ackError) {
      debugPrint('[DeviceJobWorker] failed to report failure for $jobId: $ackError');
    }
  }
}
