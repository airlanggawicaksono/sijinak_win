import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'isapi_client.dart';
import 'hik_event.dart';

/// Listens to Hikvision alertStream (long-lived multipart/mixed GET).
/// Parses RFID tap events and emits them as [HikEvent]s.
class AlertStream {
  final HikvisionDevicePort client;
  final Duration retryDelay;

  final _controller = StreamController<HikEvent>.broadcast();
  final _statusController = StreamController<AlertStreamStatus>.broadcast();

  HttpClient? _httpClient;
  StreamSubscription? _subscription;
  bool _running = false;

  AlertStream({
    required this.client,
    this.retryDelay = const Duration(seconds: 3),
  });

  Stream<HikEvent> get events => _controller.stream;
  Stream<AlertStreamStatus> get status => _statusController.stream;

  /// The last serial number seen (for catch-up polling after reconnect).
  int lastSerialNo = 0;

  /// The last device time seen from ANY event (including non-card events).
  DateTime? lastDeviceTime;

  void start() {
    if (_running) return;
    _running = true;
    _connect();
  }

  void stop() {
    _running = false;
    _subscription?.cancel();
    _subscription = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    _statusController.add(AlertStreamStatus.disconnected);
  }

  void dispose() {
    stop();
    _controller.close();
    _statusController.close();
  }

  Future<void> _connect() async {
    if (!_running) return;
    _statusController.add(AlertStreamStatus.connecting);

    try {
      final (response, httpClient) = await client
          .getStream('/ISAPI/Event/notification/alertStream');
      _httpClient = httpClient;

      // Extract boundary from Content-Type
      final contentType = response.headers.contentType?.toString() ?? '';
      final boundary = _extractBoundary(contentType);

      _statusController.add(AlertStreamStatus.connected);

      final buffer = StringBuffer();

      _subscription = response.transform(utf8.decoder).listen(
        (chunk) {
          buffer.write(chunk);

          // Try to extract complete events from buffer
          final content = buffer.toString();
          final events = _parseEvents(content, boundary);

          if (events.isNotEmpty) {
            // Keep only unparsed remainder in buffer
            final lastBoundaryIdx = boundary != null
                ? content.lastIndexOf('--$boundary')
                : content.lastIndexOf('--');
            if (lastBoundaryIdx >= 0) {
              buffer.clear();
              buffer.write(content.substring(lastBoundaryIdx));
            }

            for (final event in events) {
              if (event.serialNo > lastSerialNo) {
                lastSerialNo = event.serialNo;
              }
              _controller.add(event);
            }
          }
        },
        onError: (error) {
          _statusController.add(AlertStreamStatus.disconnected);
          _scheduleReconnect();
        },
        onDone: () {
          _statusController.add(AlertStreamStatus.disconnected);
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _statusController.add(AlertStreamStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_running) return;
    _subscription?.cancel();
    _subscription = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    Future.delayed(retryDelay, _connect);
  }

  String? _extractBoundary(String contentType) {
    final match = RegExp(r'boundary=([^\s;]+)').firstMatch(contentType);
    return match?.group(1);
  }

  List<HikEvent> _parseEvents(String content, String? boundary) {
    final events = <HikEvent>[];

    // Try JSON parsing first (DS-K1T341 series sends JSON)
    events.addAll(_parseJsonEvents(content, boundary));

    // Fall back to XML parsing
    if (events.isEmpty) {
      events.addAll(_parseXmlEvents(content));
    }

    return events;
  }

  List<HikEvent> _parseJsonEvents(String content, String? boundary) {
    final events = <HikEvent>[];

    // Split by boundary and find JSON blocks
    final separator = boundary != null ? '--$boundary' : '--MIME_boundary';
    final parts = content.split(separator);

    for (final part in parts) {
      // Find JSON object in this part
      final jsonStart = part.indexOf('{');
      if (jsonStart < 0) continue;

      final jsonStr = part.substring(jsonStart);
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;

        // Track device time from ALL events (including non-card ones)
        final dtStr = json['dateTime'] as String?;
        if (dtStr != null) {
          try {
            lastDeviceTime = DateTime.parse(dtStr);
          } catch (_) {}
        }

        final event = _parseJsonEvent(json);
        if (event != null) {
          events.add(event);
        }
      } catch (_) {
        // Incomplete JSON, skip
      }
    }

    return events;
  }

  HikEvent? _parseJsonEvent(Map<String, dynamic> json) {
    final ace = json['AccessControllerEvent'] as Map<String, dynamic>?;

    final rfidNumber = json['cardNo'] as String? ??
        ace?['cardNo'] as String?;
    if (rfidNumber == null || rfidNumber.isEmpty) return null;

    final dateTimeStr = json['dateTime'] as String? ??
        ace?['time'] as String?;
    final serialNo = ace?['serialNo'] as int? ??
        json['serialNo'] as int? ?? 0;
    final employeeNo = json['employeeNoString'] as String? ??
        ace?['employeeNoString'] as String?;

    // DS-K series: "breakIn", "breakOut", "checkIn", "checkOut", "overtimeIn", "overtimeOut"
    final attendanceStatus = ace?['attendanceStatus'] as String? ??
        json['attendanceStatus'] as String?;

    DateTime dateTime;
    try {
      dateTime = dateTimeStr != null
          ? DateTime.parse(dateTimeStr)
          : DateTime.now();
    } catch (_) {
      dateTime = DateTime.now();
    }

    return HikEvent(
      rfidNumber: rfidNumber,
      employeeNo: employeeNo,
      dateTime: dateTime,
      serialNo: serialNo,
      attendanceStatus: attendanceStatus,
    );
  }

  List<HikEvent> _parseXmlEvents(String content) {
    final events = <HikEvent>[];
    final alertPattern = RegExp(
      r'<EventNotificationAlert[^>]*>(.*?)</EventNotificationAlert>',
      dotAll: true,
    );

    for (final match in alertPattern.allMatches(content)) {
      final xml = match.group(0)!;
      final event = _parseXmlEvent(xml);
      if (event != null) {
        events.add(event);
      }
    }

    return events;
  }

  HikEvent? _parseXmlEvent(String xml) {
    final rfidNumber = _extractTag(xml, 'cardNo');
    if (rfidNumber == null || rfidNumber.isEmpty) return null;

    final dateTimeStr = _extractTag(xml, 'dateTime');
    final serialNoStr = _extractTag(xml, 'serialNo');
    final employeeNo = _extractTag(xml, 'employeeNoString');
    final attendanceStatusStr = _extractTag(xml, 'attendanceStatus');

    DateTime dateTime;
    try {
      dateTime = dateTimeStr != null
          ? DateTime.parse(dateTimeStr)
          : DateTime.now();
    } catch (_) {
      dateTime = DateTime.now();
    }

    return HikEvent(
      rfidNumber: rfidNumber,
      employeeNo: employeeNo,
      dateTime: dateTime,
      serialNo: int.tryParse(serialNoStr ?? '0') ?? 0,
      attendanceStatus: attendanceStatusStr,
    );
  }

  String? _extractTag(String xml, String tag) {
    final match = RegExp('<$tag>(.*?)</$tag>').firstMatch(xml);
    return match?.group(1);
  }

}

enum AlertStreamStatus {
  disconnected,
  connecting,
  connected,
}
