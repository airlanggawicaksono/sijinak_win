import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import '../data/local/database.dart';
import '../data/remote/api_client.dart';
import '../data/remote/dto/izin_dispatch_request_dto.dart';
import '../data/remote/dto/izin_dispatch_result_dto.dart';
import '../data/remote/dto/wablas_send_message_request_dto.dart';
import '../utils/phone_id.dart';

class IzinDispatchService {
  final BackendApiPort Function(AppConfig config) _apiFactory;
  final StudentStorePort _studentStore;

  IzinDispatchService({
    BackendApiPort Function(AppConfig config)? apiFactory,
    StudentStorePort? studentStore,
  })  : _apiFactory = apiFactory ?? ((config) => ApiClient.fromConfig(config)),
        _studentStore = studentStore ?? AppDatabase.instance;

  Future<IzinDispatchResultDTO> dispatch({
    required AppConfig config,
    required IzinDispatchRequestDTO request,
  }) async {
    bool backendAccepted = false;
    DateTime? backendPublishedAt;
    String? backendError;
    bool wablasSent = false;
    String? wablasError;

    if (config.isServerConfigured) {
      try {
        final api = _apiFactory(config);
        final results = await api.syncAttendance([request.toAttendanceEventPayload()]);

        if (results.isNotEmpty && results.first['status'] == 'ok') {
          backendAccepted = true;
          final publishedAtRaw = results.first['published_at'] as String?;
          if (publishedAtRaw != null && publishedAtRaw.isNotEmpty) {
            backendPublishedAt = DateTime.tryParse(publishedAtRaw);
          }
        } else {
          backendError = (results.isNotEmpty
              ? (results.first['detail']?.toString() ?? 'Sync rejected')
              : 'Empty sync response');
        }
      } catch (e) {
        backendError = e.toString();
      }
    } else {
      backendError = 'Server belum dikonfigurasi.';
    }

    if (config.isWablasConfigured) {
      try {
        final phone = await _findGuardianPhone(request.userId);
        if (phone == null || phone.isEmpty) {
          // Graceful skip — student has no guardian phone on file.
          wablasError = null;
        } else {
          final parsed = PhoneId.parse(phone);
          if (!parsed.valid) {
            wablasError = parsed.error;
          } else {
            final sent = await _sendWablas(
              baseUrl: config.wablasBaseUrl,
              apiKey: config.wablasApiKey,
              secKey: config.wablasSecKey,
              request: WablasSendMessageRequestDTO(
                phone: parsed.canonical!,
                message: _buildIzinMessage(request),
              ),
            );
            wablasSent = sent;
            if (!sent) {
              wablasError = 'Wablas menolak request.';
            }
          }
        }
      } catch (e) {
        wablasError = e.toString();
      }
    } else {
      wablasError = 'Wablas belum dikonfigurasi.';
    }

    return IzinDispatchResultDTO(
      backendAccepted: backendAccepted,
      backendPublishedAt: backendPublishedAt,
      wablasSent: wablasSent,
      backendError: backendError,
      wablasError: wablasError,
    );
  }

  Future<String?> _findGuardianPhone(String userId) async {
    final student = await _studentStore.getStudentByUserId(userId);
    return student?.noTelpWali;
  }

  static String _buildIzinMessage(IzinDispatchRequestDTO request) {
    final kembali = request.perkiraanKembali == null
        ? 'tidak disebutkan'
        : '${request.perkiraanKembali!.hour.toString().padLeft(2, '0')}:${request.perkiraanKembali!.minute.toString().padLeft(2, '0')}';
    final nisn = (request.nisn == null || request.nisn!.isEmpty) ? '-' : request.nisn!;

    return [
      '*[Izin Keluar Siswa]*',
      'Nama: ${request.studentName}',
      'NISN: $nisn',
      'Alasan: ${request.reason}',
      'Perkiraan kembali: $kembali',
    ].join('\n');
  }

  Future<bool> testWebhook({
    required AppConfig config,
    required String phone,
  }) async {
    if (!config.isWablasConfigured) {
      throw Exception('Wablas belum dikonfigurasi.');
    }
    return _sendWablas(
      baseUrl: config.wablasBaseUrl,
      apiKey: config.wablasApiKey,
      secKey: config.wablasSecKey,
      request: WablasSendMessageRequestDTO(
        phone: phone,
        message: '*[Test Webhook SIJINAK]*\nIni adalah pesan uji dari aplikasi SIJINAK.\nKonfigurasi Wablas berhasil terhubung.',
      ),
    );
  }

  Future<bool> _sendWablas({
    required String baseUrl,
    required String apiKey,
    required String secKey,
    required WablasSendMessageRequestDTO request,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final url = '$base/api/send-message';

    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.authorizationHeader, '$apiKey.$secKey');
      req.headers.contentType =
          ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');

      final payload = request.toFormPayload();
      req.write(Uri(queryParameters: payload).query);

      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        String detail = body;
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          detail = json['message']?.toString() ?? body;
        } catch (_) {}
        throw Exception('Wablas HTTP ${resp.statusCode}: $detail');
      }
      return true;
    } finally {
      client.close(force: true);
    }
  }
}
