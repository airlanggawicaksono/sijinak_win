import 'package:flutter/foundation.dart';

import '../../data/hikvision/isapi_client.dart';
import '../../data/local/database.dart';
import '../../data/remote/desktop_event_bus.dart';

/// Reacts to BE student deletions by:
///   1. Forgetting all local state (Students row + unpublished TapRecords +
///      pending CardOutbox/HikOutbox rows for this user).
///   2. Enqueuing a fresh HikOutbox deletePerson so the local HikSyncWorker
///      removes the person + card from the Hikvision device.
///
/// Payload shape (see `publish_student_deleted` on BE):
///   { user_id: str, rfid_number: str | null }
class StudentDeletedSubscriber implements TopicSubscriber {
  static const topic = 'desktop.student.deleted';

  final AppDatabase db;

  StudentDeletedSubscriber({required this.db});

  @override
  List<String> get topics => const [topic];

  @override
  Future<void> onEvent(String topic, dynamic data) async {
    if (data is! Map<String, dynamic>) return;
    final userId = (data['user_id'] as String?)?.trim();
    if (userId == null || userId.isEmpty) return;

    try {
      // forgetStudent wipes any in-flight outbox rows for this user so the
      // worker won't try to upsert a card belonging to a deleted student. We
      // then enqueue the deletePerson row fresh so the device converges.
      await db.forgetStudent(userId);
      await db.enqueueHikWrite(
        userId: userId,
        employeeNo: hikvisionEmployeeNoFor(userId),
        operation: HikOpType.deletePerson,
      );
      debugPrint('[StudentDeletedSubscriber] purge enqueued for $userId');
    } catch (e) {
      debugPrint('[StudentDeletedSubscriber] forget failed for $userId: $e');
    }
  }
}
