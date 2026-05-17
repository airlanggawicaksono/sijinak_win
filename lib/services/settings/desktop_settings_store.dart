import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/remote/api_client.dart';
import '../../data/remote/desktop_event_bus.dart';
import '../../data/remote/dto/desktop_settings_dto.dart';

/// In-memory replica of the BE-canonical desktop settings.
///
/// Populated by:
///   1. Initial GET on `start()` (the safety net for missed WS events).
///   2. `desktop.settings.changed` pubsub frames, which carry the new shape
///      so no extra fetch is needed.
///
/// UI surfaces (tap popup, settings screen badge) read via [current].
/// `addListener` for reactive widgets.
class DesktopSettingsStore extends ChangeNotifier implements TopicSubscriber {
  static const topic = 'desktop.settings.changed';

  final BackendApiPort api;
  DesktopSettingsDTO? _current;

  DesktopSettingsStore({required this.api});

  DesktopSettingsDTO? get current => _current;

  @override
  List<String> get topics => const [topic];

  /// One-shot fetch; safe to call again after server reachability changes.
  Future<void> refreshFromServer() async {
    try {
      final fresh = await api.getDesktopSettings();
      _setIfChanged(fresh);
    } catch (e) {
      debugPrint('[DesktopSettingsStore] refresh failed: $e');
    }
  }

  @override
  Future<void> onEvent(String topic, dynamic data) async {
    if (data is! Map<String, dynamic>) return;
    final fresh = DesktopSettingsDTO.fromJson(data);
    _setIfChanged(fresh);
  }

  void _setIfChanged(DesktopSettingsDTO fresh) {
    if (_current == fresh) return;
    _current = fresh;
    notifyListeners();
  }
}
