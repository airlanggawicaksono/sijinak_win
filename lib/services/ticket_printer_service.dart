import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

class IzinTicketPayload {
  final String studentName;
  final String? nisn;
  final String alasanIzin;
  final DateTime waktuKeluar;
  final DateTime? perkiraanKembali;

  const IzinTicketPayload({
    required this.studentName,
    required this.nisn,
    required this.alasanIzin,
    required this.waktuKeluar,
    required this.perkiraanKembali,
  });
}

class TicketPrinterDevice {
  final String key;
  final String name;
  final String? address;

  const TicketPrinterDevice({
    required this.key,
    required this.name,
    this.address,
  });
}

abstract class TicketPrinterPort {
  Future<bool> isPrinterReady({String? preferredPrinterKey});

  Future<List<TicketPrinterDevice>> scanUsbPrinters();

  Future<void> printTest({String? preferredPrinterKey});

  Future<void> printIzinTicket(
    IzinTicketPayload payload, {
    required int copyNumber,
    String? preferredPrinterKey,
  });
}

class TicketPrinterService implements TicketPrinterPort {
  final FlutterThermalPrinter _printerPlugin;
  Printer? _cachedPrinter;

  TicketPrinterService({FlutterThermalPrinter? printerPlugin})
    : _printerPlugin = printerPlugin ?? FlutterThermalPrinter.instance;

  @override
  Future<bool> isPrinterReady({String? preferredPrinterKey}) async {
    try {
      await _resolvePrinter(preferredPrinterKey: preferredPrinterKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<TicketPrinterDevice>> scanUsbPrinters() async {
    final printers = await _scanUsbPrinters();
    return printers
        .map(
          (p) => TicketPrinterDevice(
            key: _printerKey(p),
            name: p.name ?? 'Unknown Printer',
            address: p.address,
          ),
        )
        .toList();
  }

  @override
  Future<void> printIzinTicket(
    IzinTicketPayload payload, {
    required int copyNumber,
    String? preferredPrinterKey,
  }) async {
    final printer = await _resolvePrinter(
      preferredPrinterKey: preferredPrinterKey,
    );
    final bytes = await _buildTicketBytes(payload, copyNumber);
    await _printerPlugin.printData(printer, bytes, longData: true);
  }

  @override
  Future<void> printTest({String? preferredPrinterKey}) async {
    final printer = await _resolvePrinter(
      preferredPrinterKey: preferredPrinterKey,
    );
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final out = <int>[];

    out.addAll(
      generator.text(
        'SIJINAK - TEST PRINT',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
    );
    out.addAll(generator.hr(ch: '-'));
    out.addAll(
      generator.text(
        'Matahari terbit perlahan,\n'
        'angin pagi membawa tenang,\n'
        'langkah kecil hari ini,\n'
        'menjadi besar esok nanti.',
        styles: const PosStyles(align: PosAlign.left),
      ),
    );
    out.addAll(generator.hr(ch: '-'));
    out.addAll(
      generator.text(
        'Waktu: ${DateTime.now().toLocal()}',
        styles: const PosStyles(align: PosAlign.left),
      ),
    );
    out.addAll(generator.feed(2));
    out.addAll(generator.cut());

    await _printerPlugin.printData(printer, out, longData: true);
  }

  Future<Printer> _resolvePrinter({String? preferredPrinterKey}) async {
    final printers = await _scanUsbPrinters();
    if (printers.isEmpty) {
      throw Exception('Printer thermal tidak ditemukan');
    }

    final picked = _pickPreferredPrinter(
      printers,
      preferredPrinterKey: preferredPrinterKey,
    );
    _cachedPrinter = picked;
    return picked;
  }

  Future<List<Printer>> _scanUsbPrinters() async {
    final seen = <String, Printer>{};
    late final StreamSubscription<List<Printer>> sub;

    sub = _printerPlugin.devicesStream.listen((devices) {
      for (final d in devices) {
        if (d.connectionType == ConnectionType.USB) {
          final key = '${d.name}_${d.address}_${d.vendorId}_${d.productId}';
          seen[key] = d;
        }
      }
    });

    try {
      await _printerPlugin.getPrinters(
        refreshDuration: const Duration(milliseconds: 700),
        connectionTypes: const [ConnectionType.USB],
      );
      await Future.delayed(const Duration(seconds: 3));
    } finally {
      if (!Platform.isWindows) {
        try {
          await _printerPlugin.stopScan();
        } catch (_) {
          // Ignore stop-scan failures on non-Windows targets.
        }
      }
      await sub.cancel();
    }

    return seen.values.toList();
  }

  Printer _pickPreferredPrinter(
    List<Printer> printers, {
    String? preferredPrinterKey,
  }) {
    if (preferredPrinterKey != null && preferredPrinterKey.trim().isNotEmpty) {
      for (final p in printers) {
        if (_printerKey(p) == preferredPrinterKey.trim()) {
          return p;
        }
      }
    }

    if (_cachedPrinter != null) {
      final cachedKey = _printerKey(_cachedPrinter!);
      for (final p in printers) {
        if (_printerKey(p) == cachedKey) {
          return p;
        }
      }
    }

    int score(Printer p) {
      final name = (p.name ?? '').toLowerCase();
      if (name.contains('xprinter')) return 100;
      if (name.contains('thermal')) return 90;
      if (name.contains('receipt')) return 80;
      if (name.contains('pos')) return 70;
      return 10;
    }

    final sorted = [...printers]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted.first;
  }

  String _printerKey(Printer p) {
    return '${p.name ?? ''}|${p.address ?? ''}|${p.vendorId ?? ''}|${p.productId ?? ''}';
  }

  Future<List<int>> _buildTicketBytes(
    IzinTicketPayload payload,
    int copyNumber,
  ) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final out = <int>[];

    out.addAll(
      generator.text(
        'SIJINAK MAN 2 Yogyakarta',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
    );
    out.addAll(
      generator.text(
        'TIKET IZIN KELUAR',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      ),
    );
    out.addAll(
      generator.text(
        'COPY $copyNumber',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    out.addAll(generator.hr(ch: '-'));

    out.addAll(generator.text('Nama : ${payload.studentName}'));
    out.addAll(
      generator.text(
        'NISN : ${payload.nisn?.trim().isNotEmpty == true ? payload.nisn!.trim() : '-'}',
      ),
    );
    out.addAll(generator.text('Alasan Izin : ${payload.alasanIzin}'));
    out.addAll(
      generator.text('Waktu keluar : ${_fmtDateTime(payload.waktuKeluar)}'),
    );
    out.addAll(
      generator.text(
        'Perkiraan kembali : ${payload.perkiraanKembali == null ? '-' : _fmtDateTime(payload.perkiraanKembali!)}',
      ),
    );

    out.addAll(generator.feed(2));
    out.addAll(generator.cut());
    return out;
  }

  String _fmtDateTime(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString().padLeft(4, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$d-$m-$y $hh:$mm';
  }
}
