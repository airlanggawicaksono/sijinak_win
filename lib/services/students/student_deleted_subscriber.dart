import 'package:flutter/foundation.dart';

import '../../data/local/database.dart';
import '../../data/remote/desktop_event_bus.dart';

/// Reacts to BE student deletions by removing the local Drift row and any
/// unpublished TapRecords for that user. Pairs with the `hik.person.delete`
/// DeviceJob which removes the person + card from Hikvision asynchronously.
///
/// Payload shape (see `publish_student_deleted` on BE):
///   { user_id: str, rfid_number: str | null }
class StudentDeletedSubscriber implements TopicSubscriber {
  static const topic = 'desktop.student.deleted';

  final StudentDeletionPort db;

  StudentDeletedSubscriber({required this.db});

  @override
  List<String> get topics => const [topic];

  @override
  Future<void> onEvent(String topic, dynamic data) async {
    if (data is! Map<String, dynamic>) return;
    final userId = (data['user_id'] as String?)?.trim();
    if (userId == null || userId.isEmpty) return;

    try {
      await db.forgetStudent(userId);
      debugPrint('[StudentDeletedSubscriber] forgot local state for $userId');
    } catch (e) {
      debugPrint('[StudentDeletedSubscriber] forget failed for $userId: $e');
    }
  }
}
