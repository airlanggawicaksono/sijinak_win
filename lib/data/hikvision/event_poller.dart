import 'dart:convert';
import 'isapi_client.dart';
import 'hik_event.dart';

/// Polls Hikvision AcsEvent endpoint to catch events missed
/// during alertStream disconnections.
class EventPoller {
  final HikvisionDevicePort client;

  EventPoller({required this.client});

  /// Poll events starting from [beginSerialNo].
  /// Returns list of events and whether there are more to fetch.
  Future<PollResult> poll({
    required int beginSerialNo,
    int maxResults = 30,
  }) async {
    final body = await client.postJson(
      '/ISAPI/AccessControl/AcsEvent?format=json',
      {
        'AcsEventCond': {
          'searchID': 'poll',
          'searchResultPosition': 0,
          'maxResults': maxResults,
          'major': 5,
          'minor': 0,
          'beginSerialNo': beginSerialNo,
        },
      },
    );

    final json = jsonDecode(body) as Map<String, dynamic>;
    final acsEvent = json['AcsEvent'] as Map<String, dynamic>? ?? {};
    final infoList = acsEvent['InfoList'] as List<dynamic>? ?? [];
    final hasMore = acsEvent['responseStatusStrg'] == 'MORE';

    final events = <HikEvent>[];
    for (final info in infoList) {
      final map = info as Map<String, dynamic>;
      final rfidNumber = map['cardNo'] as String?;
      if (rfidNumber == null || rfidNumber.isEmpty) continue;

      DateTime dateTime;
      try {
        dateTime = DateTime.parse(map['time'] as String? ?? '');
      } catch (_) {
        dateTime = DateTime.now();
      }

      events.add(HikEvent(
        rfidNumber: rfidNumber,
        employeeNo: map['employeeNoString'] as String?,
        dateTime: dateTime,
        serialNo: map['serialNo'] as int? ?? 0,
      ));
    }

    return PollResult(events: events, hasMore: hasMore);
  }

  /// Poll all events from [beginSerialNo], paging through if needed.
  Future<List<HikEvent>> pollAll({required int beginSerialNo}) async {
    final allEvents = <HikEvent>[];
    var currentSerial = beginSerialNo;

    while (true) {
      final result = await poll(beginSerialNo: currentSerial);
      allEvents.addAll(result.events);

      if (!result.hasMore || result.events.isEmpty) break;

      // Move past the last event we received
      currentSerial = result.events.last.serialNo + 1;
    }

    return allEvents;
  }
}

class PollResult {
  final List<HikEvent> events;
  final bool hasMore;

  PollResult({required this.events, required this.hasMore});
}
