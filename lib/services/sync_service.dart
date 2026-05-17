import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../data/local/database.dart';
import '../data/remote/api_client.dart';
import 'izin_payload.dart';

class SyncService {
  final SyncStorePort db;
  final BackendApiPort Function(AppConfig config) _apiFactory;

  SyncService(
    this.db, {
    BackendApiPort Function(AppConfig config)? apiFactory,
  }) : _apiFactory = apiFactory ?? ((config) => ApiClient.fromConfig(config));

  /// Manually sync all unpublished records via HTTP POST.
  /// Used for the "Simplex" contract and offline catch-up.
  Future<int> manualBulkSync(AppConfig config) async {
    final pending = await db.getUnpublishedRecords();
    if (pending.isEmpty) return 0;

    final api = _apiFactory(config);
    final events = <Map<String, dynamic>>[];
    
    // Prepare events
    for (final record in pending) {
      final userIdFromRecordId = _extractUserIdFromRecordId(record.id);
      String? resolvedUserId = userIdFromRecordId;
      if (resolvedUserId == null) {
        final student = await db.getStudentByCard(record.rfidNumber);
        resolvedUserId = student?.userId;
      }
      if (resolvedUserId == null || resolvedUserId.isEmpty) continue;
      final izinPayload = decodeIzinReasonPayload(record.reason);

      events.add({
        'record_id': record.id,
        'user_id': resolvedUserId,
        'event_type': record.eventType,
        'device_time': DateTime.fromMillisecondsSinceEpoch(record.deviceTime * 1000).toIso8601String(),
        'reason': izinPayload.reason ?? record.reason,
        'perkiraan_kembali': izinPayload.perkiraanKembali?.toIso8601String(),
      });
    }

    if (events.isEmpty) return 0;

    // Push to server
    final results = await api.syncAttendance(events);
    int successCount = 0;

    // Process results
    for (final res in results) {
      final recordId = res['record_id'] as String;
      if (res['status'] == 'ok') {
        final publishedAtStr = res['published_at'] as String?;
        int publishedAt;
        try {
          publishedAt = publishedAtStr != null 
            ? DateTime.parse(publishedAtStr).millisecondsSinceEpoch ~/ 1000
            : DateTime.now().millisecondsSinceEpoch ~/ 1000;
        } catch (_) {
          publishedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        }
        
        await db.markPublished(recordId, publishedAt);
        successCount++;
      } else {
        debugPrint('[SyncService] Failed to sync record $recordId: ${res["detail"]}');
      }
    }

    return successCount;
  }

  String? _extractUserIdFromRecordId(String recordId) {
    final match = RegExp(
      r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})_',
    ).firstMatch(recordId);
    return match?.group(1);
  }
}


