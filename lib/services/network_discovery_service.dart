import 'dart:io';

class NetworkDiscoveryService {
  static String _normalizeMac(String mac) {
    return mac
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(':', '')
        .replaceAll('.', '');
  }

  static Future<Map<String, String>> _readArpTable() async {
    final result = await Process.run('arp', ['-a']);
    final output = '${result.stdout}\n${result.stderr}';
    final reg = RegExp(
      r'(\d{1,3}(?:\.\d{1,3}){3})\s+([0-9a-fA-F:\-\.]{12,17})',
      multiLine: true,
    );

    final map = <String, String>{};
    for (final m in reg.allMatches(output)) {
      final ip = m.group(1);
      final mac = m.group(2);
      if (ip == null || mac == null) continue;
      map[_normalizeMac(mac)] = ip;
    }
    return map;
  }

  static Future<List<String>> _localPrefixes() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final prefixes = <String>{};
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final parts = addr.address.split('.');
        if (parts.length != 4) continue;
        if (parts[0] == '10' ||
            (parts[0] == '172' &&
                int.tryParse(parts[1]) != null &&
                int.parse(parts[1]) >= 16 &&
                int.parse(parts[1]) <= 31) ||
            (parts[0] == '192' && parts[1] == '168')) {
          prefixes.add('${parts[0]}.${parts[1]}.${parts[2]}');
        }
      }
    }
    return prefixes.toList();
  }

  static Future<void> _probeIp(String ip) async {
    try {
      await Process.run('ping', ['-n', '1', '-w', '250', ip]).timeout(
        const Duration(milliseconds: 600),
      );
    } catch (_) {
      // ignore probe failures
    }
  }

  static Future<void> _warmArpForPrefix(String prefix) async {
    const batchSize = 32;
    var batch = <Future<void>>[];
    for (var i = 1; i <= 254; i++) {
      final ip = '$prefix.$i';
      batch.add(_probeIp(ip));
      if (batch.length >= batchSize) {
        await Future.wait(batch);
        batch = <Future<void>>[];
      }
    }
    if (batch.isNotEmpty) {
      await Future.wait(batch);
    }
  }

  static Future<String?> findIpByMac(String targetMac) async {
    final normalized = _normalizeMac(targetMac);
    if (normalized.isEmpty) return null;

    var arp = await _readArpTable();
    if (arp.containsKey(normalized)) {
      return arp[normalized];
    }

    final prefixes = await _localPrefixes();
    for (final prefix in prefixes) {
      await _warmArpForPrefix(prefix);
      arp = await _readArpTable();
      if (arp.containsKey(normalized)) {
        return arp[normalized];
      }
    }

    return null;
  }
}
