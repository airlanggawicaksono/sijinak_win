import 'dart:convert';
import 'dart:io';

import '../../config/app_config.dart';
import 'dto/desktop_settings_dto.dart';
import 'dto/device_jobs/device_job_dto.dart';
import 'dto/student_sync_response_dto.dart';

/// Port for all sijinak → backend HTTP calls.
abstract class BackendApiPort {
  // Connectivity & student snapshot
  Future<void> testConnection();
  Future<List<StudentSyncResponseDTO>> fetchStudents();

  // Attendance
  Future<List<Map<String, dynamic>>> syncAttendance(
    List<Map<String, dynamic>> events,
  );

  // RFID card — single canonical entry point. `newRfidNumber == null` removes.
  Future<CardSetResponseDTO> setStudentCard(String userId, String? newRfidNumber);

  // Desktop-scoped read settings (late cutoff, etc.). Edits stay admin-only via FE.
  Future<DesktopSettingsDTO> getDesktopSettings();

  // DeviceJob outbox API (worker)
  Future<List<DeviceJobDTO>> listPendingJobs({
    required List<String> types,
    int limit = 50,
  });
  Future<ClaimResponseDTO> claimJob({required String jobId, required String deviceId});
  Future<void> completeJob({required String jobId, required String deviceId});
  Future<void> failJob({
    required String jobId,
    required String deviceId,
    required String error,
    int? retryInSeconds,
  });
}

class ApiClient implements BackendApiPort {
  final String baseUrl;
  final String apiKey;

  ApiClient({required String baseUrl, required this.apiKey})
      : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  factory ApiClient.fromConfig(AppConfig config) =>
      ApiClient(baseUrl: config.serverUrl, apiKey: config.apiKey);

  // ── Connectivity ────────────────────────────────────────────────────

  @override
  Future<void> testConnection() async {
    await _get('/api/desktop/ping', timeout: const Duration(seconds: 10));
  }

  @override
  Future<List<StudentSyncResponseDTO>> fetchStudents() async {
    final body = await _get('/api/desktop/students', timeout: const Duration(seconds: 15));
    final list = jsonDecode(body) as List;
    return list
        .cast<Map<String, dynamic>>()
        .map(StudentSyncResponseDTO.fromJson)
        .toList();
  }

  // ── Attendance ──────────────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> syncAttendance(
    List<Map<String, dynamic>> events,
  ) async {
    final body = await _post(
      '/api/desktop/sync-attendance',
      bodyJson: {'events': events},
      timeout: const Duration(seconds: 30),
    );
    final data = jsonDecode(body) as Map<String, dynamic>;
    return (data['results'] as List).cast<Map<String, dynamic>>();
  }

  // ── Card ────────────────────────────────────────────────────────────

  @override
  Future<CardSetResponseDTO> setStudentCard(String userId, String? newRfidNumber) async {
    final body = await _post(
      '/api/desktop/students/$userId/card',
      bodyJson: {'rfid_number': newRfidNumber},
      timeout: const Duration(seconds: 15),
    );
    return CardSetResponseDTO.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  // ── Settings ────────────────────────────────────────────────────────

  @override
  Future<DesktopSettingsDTO> getDesktopSettings() async {
    final body = await _get('/api/desktop/settings', timeout: const Duration(seconds: 10));
    return DesktopSettingsDTO.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  // ── DeviceJob worker API ────────────────────────────────────────────

  @override
  Future<List<DeviceJobDTO>> listPendingJobs({
    required List<String> types,
    int limit = 50,
  }) async {
    final qs = 'types=${Uri.encodeQueryComponent(types.join(','))}&limit=$limit';
    final body = await _get('/api/desktop/jobs?$qs', timeout: const Duration(seconds: 15));
    final list = jsonDecode(body) as List;
    return list.cast<Map<String, dynamic>>().map(DeviceJobDTO.fromJson).toList();
  }

  @override
  Future<ClaimResponseDTO> claimJob({required String jobId, required String deviceId}) async {
    final body = await _post(
      '/api/desktop/jobs/$jobId/claim',
      bodyJson: {'device_id': deviceId},
      timeout: const Duration(seconds: 15),
    );
    return ClaimResponseDTO.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  @override
  Future<void> completeJob({required String jobId, required String deviceId}) async {
    await _post(
      '/api/desktop/jobs/$jobId/complete',
      bodyJson: {'device_id': deviceId},
      timeout: const Duration(seconds: 15),
    );
  }

  @override
  Future<void> failJob({
    required String jobId,
    required String deviceId,
    required String error,
    int? retryInSeconds,
  }) async {
    final payload = <String, dynamic>{
      'device_id': deviceId,
      'error': error,
    };
    if (retryInSeconds != null) payload['retry_in_seconds'] = retryInSeconds;
    await _post(
      '/api/desktop/jobs/$jobId/fail',
      bodyJson: payload,
      timeout: const Duration(seconds: 15),
    );
  }

  // ── HTTP helpers ────────────────────────────────────────────────────

  Future<String> _get(String path, {required Duration timeout}) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final req = await client.getUrl(Uri.parse('$baseUrl$path'));
      req.headers.set('X-API-Key', apiKey);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      _ensureOk(resp.statusCode, body);
      return body;
    } finally {
      client.close();
    }
  }

  Future<String> _post(
    String path, {
    required Map<String, dynamic> bodyJson,
    required Duration timeout,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = timeout;
    try {
      final req = await client.postUrl(Uri.parse('$baseUrl$path'));
      req.headers.set('X-API-Key', apiKey);
      req.headers.set('Content-Type', 'application/json');
      req.add(utf8.encode(jsonEncode(bodyJson)));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      _ensureOk(resp.statusCode, body);
      return body;
    } finally {
      client.close();
    }
  }

  void _ensureOk(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) return;
    if (statusCode == 401 || statusCode == 403) {
      throw ApiException('Invalid API key', statusCode);
    }
    if (statusCode == 404) {
      throw ApiException(_extractDetail(body, fallback: 'Not found'), statusCode);
    }
    if (statusCode == 409) {
      throw ApiException(_extractDetail(body, fallback: 'Conflict'), statusCode);
    }
    throw ApiException('HTTP $statusCode: $body', statusCode);
  }

  String _extractDetail(String body, {required String fallback}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
      }
    } catch (_) {}
    return fallback;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
