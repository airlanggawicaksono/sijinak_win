import 'dart:async';
import '../config/app_config.dart';
import '../data/hikvision/isapi_client.dart';
import '../data/hikvision/alert_stream.dart';
import '../data/hikvision/event_poller.dart';
import '../data/hikvision/hik_event.dart';

/// Orchestrates Hikvision alertStream + polling catch-up.
///
/// Flow:
/// 1. Opens alertStream for real-time events
/// 2. On reconnect, polls AcsEvent to catch missed events during the gap
/// 3. Emits all events through a unified stream
class HikvisionService {
  final HikvisionDevicePort Function(AppConfig config) _clientFactory;
  HikvisionDevicePort? _client;
  AlertStream? _alertStream;
  EventPoller? _poller;
  StreamSubscription? _statusSub;
  StreamSubscription? _eventSub;
  bool _wasConnected = false;

  final _eventController = StreamController<HikEvent>.broadcast();
  final _statusController = StreamController<AlertStreamStatus>.broadcast();

  Stream<HikEvent> get events => _eventController.stream;
  Stream<AlertStreamStatus> get status => _statusController.stream;
  AlertStreamStatus _currentStatus = AlertStreamStatus.disconnected;
  AlertStreamStatus get currentStatus => _currentStatus;

  HikvisionService({
    HikvisionDevicePort Function(AppConfig config)? clientFactory,
  }) : _clientFactory = clientFactory ??
            ((config) => IsapiClient(
                  baseUrl: config.hikvisionBaseUrl,
                  username: config.hikvisionUser,
                  password: config.hikvisionPassword,
                ));

  /// The highest serialNo seen.
  int get lastSerialNo => _alertStream?.lastSerialNo ?? 0;

  /// The last device time from ANY event (including non-card noise).
  DateTime? get lastDeviceTime => _alertStream?.lastDeviceTime;

  void start(AppConfig config) {
    stop();

    if (!config.isHikvisionConfigured) return;

    _client = _clientFactory(config);

    _alertStream = AlertStream(client: _client!);
    _poller = EventPoller(client: _client!);

    // Forward events
    _eventSub = _alertStream!.events.listen((event) {
      _eventController.add(event);
    });

    // Monitor connection status for catch-up polling
    _statusSub = _alertStream!.status.listen((status) {
      _currentStatus = status;
      _statusController.add(status);

      if (status == AlertStreamStatus.connected && _wasConnected) {
        // Reconnected — poll for missed events
        _catchUp();
      }

      if (status == AlertStreamStatus.connected) {
        _wasConnected = true;
      }
    });

    _alertStream!.start();
  }

  void stop() {
    _eventSub?.cancel();
    _statusSub?.cancel();
    _alertStream?.dispose();
    _alertStream = null;
    _poller = null;
    _client = null;
    _wasConnected = false;
    _currentStatus = AlertStreamStatus.disconnected;
  }

  Future<void> _catchUp() async {
    final poller = _poller;
    final alertStream = _alertStream;
    if (poller == null || alertStream == null) return;

    final lastSerial = alertStream.lastSerialNo;
    if (lastSerial <= 0) return;

    try {
      final missed = await poller.pollAll(beginSerialNo: lastSerial + 1);
      for (final event in missed) {
        if (event.serialNo > alertStream.lastSerialNo) {
          alertStream.lastSerialNo = event.serialNo;
        }
        _eventController.add(event);
      }
    } catch (_) {
      // Polling failed — will try again on next reconnect
    }
  }

  /// Test connection to device. Returns device info on success.
  static Future<DeviceInfo> testConnection(
    AppConfig config, {
    HikvisionDevicePort Function(AppConfig config)? clientFactory,
  }) async {
    final client = (clientFactory ??
        (cfg) => IsapiClient(
              baseUrl: cfg.hikvisionBaseUrl,
              username: cfg.hikvisionUser,
              password: cfg.hikvisionPassword,
            ))(config);
    return client.testConnection(timeout: const Duration(seconds: 3));
  }
}
