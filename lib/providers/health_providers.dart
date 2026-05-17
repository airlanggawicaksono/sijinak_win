import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../data/hikvision/isapi_client.dart';
import '../data/remote/api_client.dart';
import 'providers.dart';

/// Live reachability of a remote dependency, distinct from "configured".
/// Configured = user typed values in settings.
/// Reachable  = those values actually reach a responsive host right now.
enum HealthStatus {
  /// Not yet probed (initial frame).
  unknown,

  /// User has not filled in credentials.
  notConfigured,

  /// Probing in progress.
  probing,

  /// Last probe succeeded.
  ok,

  /// Last probe failed (timeout, refused, auth, etc).
  unreachable,
}

extension HealthStatusLabel on HealthStatus {
  String get label {
    switch (this) {
      case HealthStatus.unknown:
        return '...';
      case HealthStatus.notConfigured:
        return 'Not set';
      case HealthStatus.probing:
        return 'Checking...';
      case HealthStatus.ok:
        return 'Online';
      case HealthStatus.unreachable:
        return 'Offline';
    }
  }
}

const _probeInterval = Duration(seconds: 30);

class ServerHealthNotifier extends AsyncNotifier<HealthStatus> {
  Timer? _timer;

  @override
  Future<HealthStatus> build() async {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(_probeInterval, (_) => refresh());
    return _probe();
  }

  Future<void> refresh() async {
    state = const AsyncData(HealthStatus.probing);
    state = AsyncData(await _probe());
  }

  Future<HealthStatus> _probe() async {
    final config = ref.read(configProvider).asData?.value;
    if (config == null || !config.isServerConfigured) {
      return HealthStatus.notConfigured;
    }
    try {
      final BackendApiPort api = ApiClient.fromConfig(config);
      await api.testConnection();
      return HealthStatus.ok;
    } catch (_) {
      return HealthStatus.unreachable;
    }
  }
}

class HikvisionHealthNotifier extends AsyncNotifier<HealthStatus> {
  Timer? _timer;

  @override
  Future<HealthStatus> build() async {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(_probeInterval, (_) => refresh());
    return _probe();
  }

  Future<void> refresh() async {
    state = const AsyncData(HealthStatus.probing);
    state = AsyncData(await _probe());
  }

  Future<HealthStatus> _probe() async {
    final config = ref.read(configProvider).asData?.value;
    if (config == null || !config.isHikvisionConfigured) {
      return HealthStatus.notConfigured;
    }
    try {
      final client = _hikvisionClient(config);
      await client.testConnection(timeout: const Duration(seconds: 3));
      return HealthStatus.ok;
    } catch (_) {
      return HealthStatus.unreachable;
    }
  }

  HikvisionDevicePort _hikvisionClient(AppConfig config) => IsapiClient(
        baseUrl: config.hikvisionBaseUrl,
        username: config.hikvisionUser,
        password: config.hikvisionPassword,
      );
}

final serverHealthProvider =
    AsyncNotifierProvider<ServerHealthNotifier, HealthStatus>(
  ServerHealthNotifier.new,
);

final hikvisionHealthProvider =
    AsyncNotifierProvider<HikvisionHealthNotifier, HealthStatus>(
  HikvisionHealthNotifier.new,
);
