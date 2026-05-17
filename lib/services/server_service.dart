import '../data/remote/api_client.dart';

/// Result of a server connection test.
class ServerTestResult {
  final bool success;
  final String message;
  final String? errorField; // 'url' or 'key'

  const ServerTestResult({
    required this.success,
    required this.message,
    this.errorField,
  });
}

class ServerService {
  /// Test server connection with the given URL and API key.
  static Future<ServerTestResult> testConnection(String url, String apiKey) async {
    try {
      final BackendApiPort api = ApiClient(baseUrl: url, apiKey: apiKey);
      await api.testConnection();
      return const ServerTestResult(success: true, message: 'Connected to server');
    } catch (e) {
      String msg = e.toString();
      String? field = 'url';
      
      if (e is ApiException) {
        msg = e.message;
        if (e.statusCode == 401 || e.statusCode == 403) {
          field = 'key';
        }
      } else {
        if (msg.contains('Connection refused') ||
            msg.contains('SocketException') ||
            msg.contains('No route to host')) {
          msg = 'Cannot reach server — check URL and network';
        } else if (msg.contains('timed out') ||
            msg.contains('TimeoutException')) {
          msg = 'Connection timed out';
        } else if (msg.contains('FormatException') ||
            msg.contains('Invalid URI')) {
          msg = 'Invalid URL format';
        }
      }
      
      return ServerTestResult(success: false, message: msg, errorField: field);
    }
  }
}

