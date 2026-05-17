import 'package:flutter/foundation.dart';

import '../../data/local/database.dart';
import '../../data/remote/desktop_event_bus.dart';

/// Listens for BE-side absensi mutations (FE admin edit/delete, or fan-out
/// from another sijinak's sync push) and drops matching local TapRecords so
/// the "already signed off" lock in [AttendanceService] re-evaluates fresh.
///
/// Payload shape (see `publish_absensi_changed` on BE):
///   { user_ids: [str], date: "YYYY-MM-DD", kind: "upsert" | "delete" }
class AbsensiInvalidationSubscriber implements TopicSubscriber {
  static const topic = 'desktop.absensi.changed';

  final AbsensiInvalidatorPort db;

  AbsensiInvalidationSubscriber({required this.db});

  @override
  List<String> get topics => const [topic];

  @override
  Future<void> onEvent(String topic, dynamic data) async {
    if (data is! Map<String, dynamic>) return;
    final date = _parseDate(data['date'] as String?);
    if (date == null) return;
    final userIds = _parseUserIds(data['user_ids']);
    if (userIds.isEmpty) return;

    for (final userId in userIds) {
      await _dropOne(userId, date);
    }
  }

  Future<void> _dropOne(String userId, DateTime date) async {
    try {
      final dropped = await db.dropTapRecordsForUserOnDate(userId, date);
      if (dropped > 0) {
        debugPrint('[AbsensiInvalidator] dropped $dropped local row(s) for $userId on $date');
      }
    } catch (e) {
      debugPrint('[AbsensiInvalidator] failed for $userId: $e');
    }
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  List<String> _parseUserIds(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }
}
