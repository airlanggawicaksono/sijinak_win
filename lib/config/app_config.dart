import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Application config, persisted to `%APPDATA%/.../config.json`.
///
/// Two load paths gated by build mode:
///
/// * **Release** (`kReleaseMode == true`): reads only `config.json`. No
///   `.env` is loaded and no hardcoded defaults are applied. A fresh install
///   starts blank → admin must configure via Settings UI on first launch.
///   Keeps shipped binaries free of dev/test secrets and IPs.
///
/// * **Debug**: `.env` (next to the exe, or CWD) is read, combined with
///   dev-friendly defaults, then overlaid onto `config.json`. Lets the dev
///   loop hot-reload with a populated config without re-typing every field.
class AppConfig {
  String hikvisionIp;
  String hikvisionUser;
  String hikvisionPassword;
  String hikvisionMac;
  String serverUrl;
  String apiKey;
  String wablasBaseUrl;
  String wablasApiKey;
  String wablasSecKey;
  String thermalPrinterKey;
  String thermalPrinterName;

  AppConfig({
    this.hikvisionIp = '',
    this.hikvisionUser = '',
    this.hikvisionPassword = '',
    this.hikvisionMac = '',
    this.serverUrl = '',
    this.apiKey = '',
    this.wablasBaseUrl = '',
    this.wablasApiKey = '',
    this.wablasSecKey = '',
    this.thermalPrinterKey = '',
    this.thermalPrinterName = '',
  });

  String get hikvisionBaseUrl => 'http://$hikvisionIp';

  bool get isHikvisionConfigured =>
      hikvisionIp.isNotEmpty && hikvisionPassword.isNotEmpty;

  bool get isServerConfigured => serverUrl.isNotEmpty && apiKey.isNotEmpty;

  bool get isWablasConfigured =>
      wablasBaseUrl.isNotEmpty &&
      wablasApiKey.isNotEmpty &&
      wablasSecKey.isNotEmpty;

  static Future<AppConfig> load() async {
    final saved = await _readConfigJson();
    if (kReleaseMode) return _fromSaved(saved);
    final env = await _loadEnv();
    return _fromSavedWithDevOverlay(saved, env);
  }

  Future<void> save() async {
    final file = await _configFile;
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'hikvision_ip': hikvisionIp,
        'hikvision_user': hikvisionUser,
        'hikvision_password': hikvisionPassword,
        'hikvision_mac': hikvisionMac,
        'server_url': serverUrl,
        'desktop_api_key': apiKey,
        'wablas_base_url': wablasBaseUrl,
        'wablas_api_key': wablasApiKey,
        'wablas_sec_key': wablasSecKey,
        'thermal_printer_key': thermalPrinterKey,
        'thermal_printer_name': thermalPrinterName,
      }),
    );
  }

  // ── Build-mode-specific factories ────────────────────────────────────

  static AppConfig _fromSaved(Map<String, dynamic> json) {
    return AppConfig(
      hikvisionIp: _str(json['hikvision_ip']),
      hikvisionUser: _str(json['hikvision_user']),
      hikvisionPassword: _str(json['hikvision_password']),
      hikvisionMac: _str(json['hikvision_mac']),
      serverUrl: _normalizeLegacyServerUrl(json['server_url'] as String?),
      apiKey: _pickFirstNonEmpty([
        json['desktop_api_key'] as String?,
        json['api_key'] as String?, // backward compat
      ]),
      wablasBaseUrl: _str(json['wablas_base_url']),
      wablasApiKey: _str(json['wablas_api_key']),
      wablasSecKey: _str(json['wablas_sec_key']),
      thermalPrinterKey: _str(json['thermal_printer_key']),
      thermalPrinterName: _str(json['thermal_printer_name']),
    );
  }

  static AppConfig _fromSavedWithDevOverlay(
    Map<String, dynamic> json,
    Map<String, String> env,
  ) {
    return AppConfig(
      hikvisionIp: _pickFirstNonEmpty([
        json['hikvision_ip'] as String?,
        _devDefaults.hikvisionIp,
      ]),
      hikvisionUser: _pickFirstNonEmpty([
        json['hikvision_user'] as String?,
        _devDefaults.hikvisionUser,
      ]),
      hikvisionPassword: _pickFirstNonEmpty([
        json['hikvision_password'] as String?,
        env['HIK_PASSWORD'],
      ]),
      hikvisionMac: _pickFirstNonEmpty([
        json['hikvision_mac'] as String?,
        env['HIK_MAC'],
        _devDefaults.hikvisionMac,
      ]),
      serverUrl: _pickFirstNonEmpty([
        env['BACKEND_URL'],
        _normalizeLegacyServerUrl(json['server_url'] as String?),
      ]),
      apiKey: _pickFirstNonEmpty([
        env['DESKTOP_API_KEY'],
        json['desktop_api_key'] as String?,
        json['api_key'] as String?,
      ]),
      wablasBaseUrl: _pickFirstNonEmpty([
        json['wablas_base_url'] as String?,
        env['WABLAS_BASE_URL'],
      ]),
      wablasApiKey: _pickFirstNonEmpty([
        json['wablas_api_key'] as String?,
        env['WABLAS_API_KEY'],
      ]),
      wablasSecKey: _pickFirstNonEmpty([
        json['wablas_sec_key'] as String?,
        env['WABLAS_SEC_KEY'],
      ]),
      thermalPrinterKey: _str(json['thermal_printer_key']),
      thermalPrinterName: _str(json['thermal_printer_name']),
    );
  }

  // ── Internals ────────────────────────────────────────────────────────

  static Future<File> get _configFile async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'config.json'));
  }

  static Future<Map<String, dynamic>> _readConfigJson() async {
    try {
      final file = await _configFile;
      if (!await file.exists()) return const {};
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }
}

// ── Dev-only defaults (never reached in release) ──────────────────────

class _DevDefaults {
  final String hikvisionIp;
  final String hikvisionUser;
  final String hikvisionMac;

  const _DevDefaults({
    required this.hikvisionIp,
    required this.hikvisionUser,
    required this.hikvisionMac,
  });
}

const _devDefaults = _DevDefaults(
  hikvisionIp: '192.168.40.181',
  hikvisionUser: 'admin',
  hikvisionMac: '4C:24:CE:99:A0:AA',
);

// ── Helpers ───────────────────────────────────────────────────────────

String _str(Object? value) => (value as String?) ?? '';

String _pickFirstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String _normalizeLegacyServerUrl(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return '';
  const legacyDefaults = {'http://localhost:2385', 'http://localhost:2385/'};
  return legacyDefaults.contains(v) ? '' : v;
}

Map<String, String> _parseEnvFile(String content) {
  final result = <String, String>{};
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx < 1) continue;
    result[trimmed.substring(0, idx).trim()] =
        trimmed.substring(idx + 1).trim();
  }
  return result;
}

Future<Map<String, String>> _loadEnv() async {
  final candidates = [
    File(p.join(p.dirname(Platform.resolvedExecutable), '.env')),
    File('.env'),
  ];
  for (final f in candidates) {
    if (await f.exists()) return _parseEnvFile(await f.readAsString());
  }
  return const {};
}
