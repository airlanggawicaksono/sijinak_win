import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PendingCardAssignment {
  final String nisn;
  final String rfidNumber;
  final int updatedAt;

  const PendingCardAssignment({
    required this.nisn,
    required this.rfidNumber,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'nisn': nisn,
        'rfid_number': rfidNumber,
        'updated_at': updatedAt,
      };

  static PendingCardAssignment? fromJson(Map<String, dynamic> json) {
    // Accept legacy "nis" key from caches written before the rename.
    final nisn = ((json['nisn'] ?? json['nis']) as String?)?.trim();
    final rfidNumber = (json['rfid_number'] as String?)?.trim();
    final updatedAt = json['updated_at'] as int?;
    if (nisn == null || nisn.isEmpty || rfidNumber == null || rfidNumber.isEmpty) {
      return null;
    }
    return PendingCardAssignment(
      nisn: nisn,
      rfidNumber: rfidNumber,
      updatedAt: updatedAt ?? 0,
    );
  }
}

abstract class PendingCardCachePort {
  Future<List<PendingCardAssignment>> listAll();
  Future<void> upsert(String nisn, String rfidNumber);
  Future<void> remove(String nisn);
}

class PendingCardCacheService implements PendingCardCachePort {
  static const _fileName = 'pending_card_assignments.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, _fileName));
  }

  Future<List<PendingCardAssignment>> _readRaw() async {
    final file = await _file();
    if (!await file.exists()) return <PendingCardAssignment>[];

    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) return <PendingCardAssignment>[];
      final decoded = jsonDecode(content);
      if (decoded is! List) return <PendingCardAssignment>[];
      return decoded
          .whereType<Map>()
          .map((e) => PendingCardAssignment.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v))))
          .whereType<PendingCardAssignment>()
          .toList();
    } catch (_) {
      return <PendingCardAssignment>[];
    }
  }

  Future<void> _writeRaw(List<PendingCardAssignment> rows) async {
    final file = await _file();
    final data = rows.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  @override
  Future<List<PendingCardAssignment>> listAll() => _readRaw();

  @override
  Future<void> upsert(String nisn, String rfidNumber) async {
    final cleanNisn = nisn.trim();
    final cleanCard = rfidNumber.trim();
    if (cleanNisn.isEmpty || cleanCard.isEmpty) return;

    final rows = List<PendingCardAssignment>.from(await _readRaw());
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final idx = rows.indexWhere((e) => e.nisn == cleanNisn);
    final item = PendingCardAssignment(
      nisn: cleanNisn,
      rfidNumber: cleanCard,
      updatedAt: now,
    );
    if (idx >= 0) {
      rows[idx] = item;
    } else {
      rows.add(item);
    }
    await _writeRaw(rows);
  }

  @override
  Future<void> remove(String nisn) async {
    final cleanNisn = nisn.trim();
    if (cleanNisn.isEmpty) return;
    final rows = List<PendingCardAssignment>.from(await _readRaw());
    rows.removeWhere((e) => e.nisn == cleanNisn);
    await _writeRaw(rows);
  }
}
