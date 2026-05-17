import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Minimal subscriber for the BE `/api/desktop/pubsub` endpoint, which speaks
/// the `fastapi-websocket-pubsub` JSON-RPC frame format.
///
/// Frame shapes we care about:
///   - We send:    {"request": {"call_id", "method": "subscribe", "arguments": {"topics": [...]}}}
///   - We receive: {"request": {"call_id", "method": "notify", "arguments": {"topic", "data"}}}
///                 (which we must ack with: {"response": {"call_id", "result": null}})
///
/// On disconnect we reconnect with exponential backoff. Missed events are
/// recovered by the worker's periodic poll, so a brief WS outage is harmless.
class DeviceJobWsClient {
  final String baseUrl;
  final String apiKey;
  final List<String> topics;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  int _attempt = 0;
  int _callId = 0;
  bool _closed = false;

  final _controller = StreamController<DeviceJobNotification>.broadcast();

  DeviceJobWsClient({
    required this.baseUrl,
    required this.apiKey,
    required this.topics,
  });

  Stream<DeviceJobNotification> get stream => _controller.stream;

  Future<void> connect() async {
    _closed = false;
    _open();
  }

  Future<void> close() async {
    _closed = true;
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    await _controller.close();
  }

  // ── Connection lifecycle ────────────────────────────────────────────

  void _open() {
    final wsUrl = _buildWsUrl();
    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel = channel;
      _sub = channel.stream.listen(
        _onFrame,
        onError: (e) => _scheduleReconnect(reason: 'error: $e'),
        onDone: () => _scheduleReconnect(reason: 'closed'),
        cancelOnError: true,
      );
      _subscribe();
      _attempt = 0;
    } catch (e) {
      _scheduleReconnect(reason: 'open failed: $e');
    }
  }

  String _buildWsUrl() {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final wsBase = base.startsWith('https')
        ? base.replaceFirst('https', 'wss')
        : base.replaceFirst('http', 'ws');
    return '$wsBase/api/desktop/pubsub';
  }

  void _scheduleReconnect({required String reason}) {
    if (_closed) return;
    debugPrint('[DeviceJobWsClient] reconnect ($reason)');
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _attempt++;
    final delaySeconds = _backoffSeconds(_attempt);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _open);
  }

  int _backoffSeconds(int attempt) {
    final raw = 2 * attempt;
    return raw > 30 ? 30 : raw;
  }

  // ── RPC frame I/O ──────────────────────────────────────────────────

  void _subscribe() {
    final callId = (++_callId).toString();
    final frame = {
      'request': {
        'call_id': callId,
        'method': 'subscribe',
        'arguments': {'topics': topics},
      },
    };
    _channel?.sink.add(jsonEncode(frame));
  }

  void _onFrame(dynamic raw) {
    final decoded = _safeDecode(raw);
    if (decoded == null) return;

    final request = decoded['request'];
    if (request is! Map<String, dynamic>) return;

    final method = request['method'] as String?;
    if (method != 'notify') return;

    _handleNotify(request);
  }

  Map<String, dynamic>? _safeDecode(dynamic raw) {
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  void _handleNotify(Map<String, dynamic> request) {
    final args = request['arguments'] as Map<String, dynamic>?;
    final callId = request['call_id'];
    _ackNotify(callId);
    if (args == null) return;

    final topic = args['topic'] as String?;
    final data = args['data'];
    if (topic == null) return;

    _controller.add(DeviceJobNotification(topic: topic, data: data));
  }

  void _ackNotify(dynamic callId) {
    if (callId == null) return;
    final ack = {
      'response': {'call_id': callId, 'result': null},
    };
    _channel?.sink.add(jsonEncode(ack));
  }
}

class DeviceJobNotification {
  final String topic;
  final dynamic data;

  const DeviceJobNotification({required this.topic, this.data});
}
