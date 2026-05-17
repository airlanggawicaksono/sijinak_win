import 'dart:io';
import 'dart:convert';
import 'hik_event.dart';

abstract class HikvisionDevicePort {
  Future<String> get(
    String path, {
    Duration connectionTimeout = const Duration(seconds: 10),
  });
  Future<String> postJson(String path, Map<String, dynamic> body);
  Future<(HttpClientResponse, HttpClient)> getStream(String path);
  Future<String> putJson(String path, Map<String, dynamic> body);
  Future<void> upsertPerson({
    required String employeeNo,
    required String name,
  });
  Future<void> upsertCard({
    required String rfidNumber,
    required String employeeNo,
  });
  Future<void> deleteCard({required String rfidNumber});
  Future<void> deletePerson({required String employeeNo});
  Future<List<HikvisionUserInfo>> listUsers({int pageSize = 200});
  Future<List<HikvisionCardInfo>> listCards({int pageSize = 200});
  Future<DeviceInfo> testConnection({
    Duration timeout = const Duration(seconds: 3),
  });
}

class IsapiClient implements HikvisionDevicePort {
  final String baseUrl;
  final String username;
  final String password;

  IsapiClient({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  HttpClient _createClient({
    Duration idleTimeout = const Duration(seconds: 15),
    Duration connectionTimeout = const Duration(seconds: 10),
  }) {
    final client = HttpClient();
    client.connectionTimeout = connectionTimeout;
    client.idleTimeout = idleTimeout;
    client.authenticate = (Uri url, String scheme, String? realm) async {
      client.addCredentials(
        Uri.parse(baseUrl),
        realm ?? '',
        HttpClientDigestCredentials(username, password),
      );
      return true;
    };
    return client;
  }

  /// GET request, returns response body as string.
  @override
  Future<String> get(
    String path, {
    Duration connectionTimeout = const Duration(seconds: 10),
  }) async {
    final client = _createClient(connectionTimeout: connectionTimeout);
    try {
      final request = await client.getUrl(Uri.parse('$baseUrl$path'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode == 401) {
        _throwAuthError(body);
      }
      if (response.statusCode != 200) {
        throw IsapiException('HTTP ${response.statusCode}', response.statusCode);
      }
      return body;
    } finally {
      client.close();
    }
  }

  /// POST with JSON body using curl (same digest auth issue as PUT).
  @override
  Future<String> postJson(String path, Map<String, dynamic> body) async {
    final url = '$baseUrl$path';
    final jsonBody = jsonEncode(body);

    final result = await Process.run('curl', [
      '--digest',
      '-u', '$username:$password',
      '--max-time', '15',
      '-sS',
      '-X', 'POST',
      '-H', 'Content-Type: application/json',
      '-d', jsonBody,
      url,
    ]);

    if (result.exitCode != 0) {
      throw IsapiException('curl failed: ${result.stderr}', result.exitCode);
    }

    final responseBody = result.stdout as String;
    if (responseBody.trim().isEmpty) {
      return '';
    }

    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final statusCode = json['statusCode'] as int?;
      if (statusCode != null && statusCode != 1) {
        throw IsapiException(
          '${json['statusString']}: ${json['subStatusCode']} - ${json['errorMsg'] ?? ''}',
          statusCode,
        );
      }
    } catch (e) {
      if (e is IsapiException) rethrow;
    }

    return responseBody;
  }

  /// Opens a long-lived GET stream (for alertStream).
  /// Caller is responsible for closing the returned [HttpClient].
  @override
  Future<(HttpClientResponse, HttpClient)> getStream(String path) async {
    final client = _createClient(idleTimeout: const Duration(hours: 24));
    final request = await client.getUrl(Uri.parse('$baseUrl$path'));
    final response = await request.close();
    if (response.statusCode == 401) {
      final body = await response.transform(utf8.decoder).join();
      client.close();
      _throwAuthError(body);
    }
    if (response.statusCode != 200) {
      client.close();
      throw IsapiException('HTTP ${response.statusCode}', response.statusCode);
    }
    return (response, client);
  }

  /// Parse 401 response body and throw the right exception.
  Never _throwAuthError(String body) {
    final lockStatus = _extractXml(body, 'lockStatus');
    if (lockStatus == 'lock') {
      final unlockTime = int.tryParse(_extractXml(body, 'unlockTime') ?? '0') ?? 0;
      throw IsapiLockException(unlockTime);
    }
    final retryLeft = int.tryParse(_extractXml(body, 'retryLoginTime') ?? '') ?? -1;
    throw IsapiAuthException(retryLeft: retryLeft > 0 ? retryLeft : null);
  }

  /// PUT request with JSON body using curl (dart HttpClient has issues with
  /// digest auth + PUT body — connection closes before retry completes).
  @override
  Future<String> putJson(String path, Map<String, dynamic> body) async {
    final url = '$baseUrl$path';
    final jsonBody = jsonEncode(body);

    final result = await Process.run('curl', [
      '--digest',
      '-u', '$username:$password',
      '--max-time', '15',
      '-sS',
      '-X', 'PUT',
      '-H', 'Content-Type: application/json',
      '-d', jsonBody,
      url,
    ]);

    if (result.exitCode != 0) {
      throw IsapiException(
        'curl failed: ${result.stderr}',
        result.exitCode,
      );
    }

    final responseBody = result.stdout as String;
    if (responseBody.trim().isEmpty) {
      return '';
    }

    // Check for error in JSON response
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final statusCode = json['statusCode'] as int?;
      if (statusCode != null && statusCode != 1) {
        throw IsapiException(
          '${json['statusString']}: ${json['subStatusCode']} - ${json['errorMsg'] ?? ''}',
          statusCode,
        );
      }
    } catch (e) {
      if (e is IsapiException) rethrow;
      // Not JSON or parse error — might still be OK
    }

    return responseBody;
  }

  /// Create or update a person on the Hikvision device.
  /// Strips hyphens from employeeNo (Hikvision max 32 chars, UUID is 36).
  /// POST Record to create, if already exists PUT SetUp to update.
  @override
  Future<void> upsertPerson({
    required String employeeNo,
    required String name,
  }) async {
    final hikId = employeeNo.replaceAll('-', '');
    final payload = {
      'UserInfo': {
        'employeeNo': hikId,
        'name': name,
        'userType': 'normal',
        'Valid': {
          'enable': true,
          'beginTime': '2024-01-01T00:00:00',
          'endTime': '2037-12-31T23:59:59',
        },
        'doorRight': '1',
        'RightPlan': [
          {'doorNo': 1, 'planTemplateNo': '1'},
        ],
      },
    };

    try {
      await postJson('/ISAPI/AccessControl/UserInfo/Record?format=json', payload);
    } on IsapiException catch (e) {
      if (e.message.toLowerCase().contains('already')) {
        await putJson('/ISAPI/AccessControl/UserInfo/SetUp?format=json', payload);
      } else {
        rethrow;
      }
    }
  }

  /// Assign a card to a person on the Hikvision device.
  /// If card already exists (from old system), delete it first then re-add.
  @override
  Future<void> upsertCard({
    required String rfidNumber,
    required String employeeNo,
  }) async {
    final hikId = employeeNo.replaceAll('-', '');
    final payload = {
      'CardInfo': {
        'cardNo': rfidNumber,
        'cardType': 'normalCard',
        'employeeNo': hikId,
      },
    };

    try {
      await postJson('/ISAPI/AccessControl/CardInfo/Record?format=json', payload);
    } on IsapiException catch (e) {
      if (e.message.toLowerCase().contains('already')) {
        // Card belongs to another person — delete first, then re-add
        await putJson('/ISAPI/AccessControl/CardInfo/Delete?format=json', {
          'CardInfoDelCond': {
            'CardNoList': [{'cardNo': rfidNumber}],
          },
        });
        await postJson('/ISAPI/AccessControl/CardInfo/Record?format=json', payload);
      } else {
        rethrow;
      }
    }
  }

  /// Delete a card from the device.
  @override
  Future<void> deleteCard({required String rfidNumber}) async {
    await putJson('/ISAPI/AccessControl/CardInfo/Delete?format=json', {
      'CardInfoDelCond': {
        'cardNoList': [
          {'cardNo': rfidNumber},
        ],
      },
    });
  }

  /// Delete a person from the device.
  @override
  Future<void> deletePerson({required String employeeNo}) async {
    final hikId = employeeNo.replaceAll('-', '');
    await putJson('/ISAPI/AccessControl/UserInfo/Delete?format=json', {
      'UserInfoDelCond': {
        'employeeNoList': [
          {'employeeNo': hikId},
        ],
      },
    });
  }

  @override
  Future<List<HikvisionUserInfo>> listUsers({int pageSize = 200}) async {
    final users = <HikvisionUserInfo>[];
    int position = 0;

    while (true) {
      final body = await postJson(
        '/ISAPI/AccessControl/UserInfo/Search?format=json',
        {
          'UserInfoSearchCond': {
            'searchID': 'sijinak-users',
            'searchResultPosition': position,
            'maxResults': pageSize,
          },
        },
      );

      if (body.trim().isEmpty) break;
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final userInfoSearch = parsed['UserInfoSearch'] as Map<String, dynamic>?;
      if (userInfoSearch == null) break;

      final matches = userInfoSearch['UserInfo'] as List<dynamic>? ?? const [];
      for (final raw in matches) {
        if (raw is! Map<String, dynamic>) continue;
        final employeeNo = (raw['employeeNo'] as String?)?.trim();
        if (employeeNo == null || employeeNo.isEmpty) continue;
        users.add(
          HikvisionUserInfo(
            employeeNo: employeeNo,
            name: (raw['name'] as String?)?.trim(),
            userType: (raw['userType'] as String?)?.trim(),
          ),
        );
      }

      final totalMatches = (userInfoSearch['totalMatches'] as int?) ?? 0;
      if (matches.isEmpty || users.length >= totalMatches) break;
      position += matches.length;
    }

    return users;
  }

  @override
  Future<List<HikvisionCardInfo>> listCards({int pageSize = 200}) async {
    final cards = <HikvisionCardInfo>[];
    int position = 0;

    while (true) {
      final body = await postJson(
        '/ISAPI/AccessControl/CardInfo/Search?format=json',
        {
          'CardInfoSearchCond': {
            'searchID': 'sijinak-cards',
            'searchResultPosition': position,
            'maxResults': pageSize,
          },
        },
      );

      if (body.trim().isEmpty) break;
      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final cardInfoSearch = parsed['CardInfoSearch'] as Map<String, dynamic>?;
      if (cardInfoSearch == null) break;

      final matches = cardInfoSearch['CardInfo'] as List<dynamic>? ?? const [];
      for (final raw in matches) {
        if (raw is! Map<String, dynamic>) continue;
        final rfidNumber = (raw['cardNo'] as String?)?.trim();
        if (rfidNumber == null || rfidNumber.isEmpty) continue;
        cards.add(
          HikvisionCardInfo(
            rfidNumber: rfidNumber,
            employeeNo: (raw['employeeNo'] as String?)?.trim(),
            cardType: (raw['cardType'] as String?)?.trim(),
          ),
        );
      }

      final totalMatches = (cardInfoSearch['totalMatches'] as int?) ?? 0;
      if (matches.isEmpty || cards.length >= totalMatches) break;
      position += matches.length;
    }

    return cards;
  }

  /// Test connection by fetching device info.
  @override
  Future<DeviceInfo> testConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final body = await get(
      '/ISAPI/System/deviceInfo',
      connectionTimeout: timeout,
    );
    return DeviceInfo(
      deviceName: _extractXml(body, 'deviceName') ?? 'Unknown',
      model: _extractXml(body, 'model') ?? 'Unknown',
      serialNumber: _extractXml(body, 'serialNumber') ?? 'Unknown',
      firmwareVersion: _extractXml(body, 'firmwareVersion') ?? 'Unknown',
    );
  }
}

/// Extract a value from simple XML like `<tag>value</tag>`.
String? _extractXml(String xml, String tag) {
  final match = RegExp('<$tag>(.*?)</$tag>').firstMatch(xml);
  return match?.group(1);
}

class IsapiException implements Exception {
  final String message;
  final int statusCode;
  IsapiException(this.message, this.statusCode);

  @override
  String toString() => 'IsapiException($statusCode): $message';
}

class HikvisionUserInfo {
  final String employeeNo;
  final String? name;
  final String? userType;

  const HikvisionUserInfo({
    required this.employeeNo,
    this.name,
    this.userType,
  });
}

class HikvisionCardInfo {
  final String rfidNumber;
  final String? employeeNo;
  final String? cardType;

  const HikvisionCardInfo({
    required this.rfidNumber,
    this.employeeNo,
    this.cardType,
  });
}

class IsapiAuthException extends IsapiException {
  final int? retryLeft;
  IsapiAuthException({this.retryLeft}) : super('Authentication failed', 401);
}

class IsapiLockException extends IsapiException {
  final int unlockSeconds;
  IsapiLockException(this.unlockSeconds) : super('Device locked', 401);
}
