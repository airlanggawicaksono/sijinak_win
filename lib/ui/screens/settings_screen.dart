import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../providers/providers.dart';
import '../../services/hikvision_service.dart';
import '../../services/network_discovery_service.dart';
import '../../services/server_service.dart';
import '../../data/hikvision/isapi_client.dart';
import '../../services/ticket_printer_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hikIpCtrl;
  late TextEditingController _hikUserCtrl;
  late TextEditingController _hikPassCtrl;
  late TextEditingController _hikMacCtrl;
  late TextEditingController _serverUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _wablasBaseUrlCtrl;
  late TextEditingController _wablasApiKeyCtrl;
  late TextEditingController _wablasSecKeyCtrl;
  late TextEditingController _thermalPrinterCtrl;
  String _thermalPrinterKey = '';
  bool _obscurePass = true;
  bool _obscureKey = true;
  bool _obscureWablasApiKey = true;
  bool _obscureWablasSecKey = true;
  bool _fieldsPopulated = false;
  bool _scanningThermal = false;
  bool _testingPrint = false;

  // Hikvision test state
  bool _testingHik = false;
  bool _detectingHikIp = false;
  String? _hikTestResult;
  bool? _hikTestSuccess;
  String? _hikErrorField;

  // Server test state
  bool _testingServer = false;
  String? _serverTestResult;
  bool? _serverTestSuccess;
  String? _serverErrorField; // 'url' or 'key'

  // Wablas test state
  bool _testingWablas = false;
  String? _wablasTestResult;
  bool? _wablasTestSuccess;

  @override
  void initState() {
    super.initState();
    _hikIpCtrl = TextEditingController();
    _hikUserCtrl = TextEditingController();
    _hikPassCtrl = TextEditingController();
    _hikMacCtrl = TextEditingController();
    _serverUrlCtrl = TextEditingController();
    _apiKeyCtrl = TextEditingController();
    _wablasBaseUrlCtrl = TextEditingController();
    _wablasApiKeyCtrl = TextEditingController();
    _wablasSecKeyCtrl = TextEditingController();
    _thermalPrinterCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _hikIpCtrl.dispose();
    _hikUserCtrl.dispose();
    _hikPassCtrl.dispose();
    _hikMacCtrl.dispose();
    _serverUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _wablasBaseUrlCtrl.dispose();
    _wablasApiKeyCtrl.dispose();
    _wablasSecKeyCtrl.dispose();
    _thermalPrinterCtrl.dispose();
    super.dispose();
  }

  void _populateFields(AppConfig config) {
    _hikIpCtrl.text = config.hikvisionIp;
    _hikUserCtrl.text = config.hikvisionUser;
    _hikPassCtrl.text = config.hikvisionPassword;
    _hikMacCtrl.text = config.hikvisionMac;
    _serverUrlCtrl.text = config.serverUrl;
    _apiKeyCtrl.text = config.apiKey;
    _wablasBaseUrlCtrl.text = config.wablasBaseUrl;
    _wablasApiKeyCtrl.text = config.wablasApiKey;
    _wablasSecKeyCtrl.text = config.wablasSecKey;
    _thermalPrinterCtrl.text = config.thermalPrinterName;
    _thermalPrinterKey = config.thermalPrinterKey;
    _fieldsPopulated = true;
  }

  void _clearHikTestState() {
    _hikTestResult = null;
    _hikTestSuccess = null;
    _hikErrorField = null;
  }

  void _clearServerTestState() {
    _serverTestResult = null;
    _serverTestSuccess = null;
    _serverErrorField = null;
  }

  // ── Hikvision Test ──────────────────────────────────────────────────

  Future<void> _testHikvision() async {
    final ip = _hikIpCtrl.text.trim();
    final user = _hikUserCtrl.text.trim();
    final pass = _hikPassCtrl.text;

    if (ip.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() {
        _clearHikTestState();
        _hikTestResult = 'Fill in IP, username, and password first';
        _hikTestSuccess = false;
      });
      return;
    }

    setState(() {
      _testingHik = true;
      _clearHikTestState();
    });

    try {
      final testConfig = AppConfig(
        hikvisionIp: ip,
        hikvisionUser: user,
        hikvisionPassword: pass,
      );
      final info = await HikvisionService.testConnection(testConfig);
      setState(() {
        _hikTestResult =
            '${info.deviceName} (${info.model})\n'
            'S/N: ${info.serialNumber}\n'
            'FW: ${info.firmwareVersion}';
        _hikTestSuccess = true;
        _hikErrorField = null;
      });
    } on IsapiLockException catch (e) {
      final minutes = (e.unlockSeconds / 60).ceil();
      setState(() {
        _hikTestResult =
            'Device is locked due to too many failed attempts.\n'
            'Try again in $minutes minute${minutes == 1 ? '' : 's'}.';
        _hikTestSuccess = false;
        _hikErrorField = 'creds';
      });
    } on IsapiAuthException catch (e) {
      final retry = e.retryLeft != null
          ? ' (${e.retryLeft} attempt${e.retryLeft == 1 ? '' : 's'} left before lock)'
          : '';
      setState(() {
        _hikTestResult = 'Wrong username or password$retry';
        _hikTestSuccess = false;
        _hikErrorField = 'creds';
      });
    } on IsapiException catch (e) {
      setState(() {
        _hikTestResult = 'Device error: ${e.message}';
        _hikTestSuccess = false;
        _hikErrorField = 'ip';
      });
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Connection refused') ||
          msg.contains('SocketException') ||
          msg.contains('No route to host')) {
        msg = 'Cannot reach device at $ip — check IP and network';
      } else if (msg.contains('timed out') ||
          msg.contains('TimeoutException')) {
        msg = 'Connection timed out — device not responding at $ip';
      }
      setState(() {
        _hikTestResult = msg;
        _hikTestSuccess = false;
        _hikErrorField = 'ip';
      });
    } finally {
      setState(() => _testingHik = false);
    }
  }

  Future<void> _autoDetectHikvisionIp() async {
    final mac = _hikMacCtrl.text.trim();
    if (mac.isEmpty) {
      setState(() {
        _clearHikTestState();
        _hikTestResult = 'Isi MAC address dulu';
        _hikTestSuccess = false;
        _hikErrorField = 'ip';
      });
      return;
    }

    setState(() {
      _detectingHikIp = true;
      _clearHikTestState();
    });

    try {
      final ip = await NetworkDiscoveryService.findIpByMac(mac);
      if (!mounted) return;

      if (ip == null) {
        setState(() {
          _hikTestResult =
              'IP tidak ditemukan untuk MAC $mac.\nPastikan perangkat satu jaringan dan aktif.';
          _hikTestSuccess = false;
          _hikErrorField = 'ip';
        });
        return;
      }

      setState(() {
        _hikIpCtrl.text = ip;
        _hikTestResult = 'IP ditemukan: $ip (MAC: $mac)';
        _hikTestSuccess = true;
        _hikErrorField = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hikTestResult = 'Gagal auto-detect IP: $e';
        _hikTestSuccess = false;
        _hikErrorField = 'ip';
      });
    } finally {
      if (mounted) {
        setState(() => _detectingHikIp = false);
      }
    }
  }

  // ── Server Test ─────────────────────────────────────────────────────

  Future<void> _testServer() async {
    final url = _serverUrlCtrl.text.trim();
    final key = _apiKeyCtrl.text.trim();

    if (url.isEmpty || key.isEmpty) {
      setState(() {
        _clearServerTestState();
        _serverTestResult = 'Fill in server URL and API key first';
        _serverTestSuccess = false;
      });
      return;
    }

    setState(() {
      _testingServer = true;
      _clearServerTestState();
    });

    final result = await ServerService.testConnection(url, key);
    if (mounted) {
      setState(() {
        _serverTestResult = result.message;
        _serverTestSuccess = result.success;
        _serverErrorField = result.errorField;
        _testingServer = false;
      });
    }
  }

  // ── Wablas Test ─────────────────────────────────────────────────────

  Future<void> _testWablas() async {
    final baseUrl = _wablasBaseUrlCtrl.text.trim();
    final apiKey = _wablasApiKeyCtrl.text.trim();
    final secKey = _wablasSecKeyCtrl.text.trim();

    if (baseUrl.isEmpty || apiKey.isEmpty || secKey.isEmpty) {
      setState(() {
        _wablasTestResult = 'Isi Wablas Base URL, API Key, dan Secret Key terlebih dahulu.';
        _wablasTestSuccess = false;
      });
      return;
    }

    final phoneCtrl = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Webhook Wablas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan nomor HP tujuan untuk pengiriman pesan uji.'),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                hintText: '628xxxxxxxxxx',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(phoneCtrl.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (phone == null || phone.isEmpty || !mounted) return;

    setState(() {
      _testingWablas = true;
      _wablasTestResult = null;
      _wablasTestSuccess = null;
    });

    try {
      final service = ref.read(izinDispatchServiceProvider);
      final tempConfig = AppConfig(
        hikvisionIp: _hikIpCtrl.text.trim(),
        hikvisionUser: _hikUserCtrl.text.trim(),
        hikvisionPassword: _hikPassCtrl.text,
        hikvisionMac: _hikMacCtrl.text.trim(),
        serverUrl: _serverUrlCtrl.text.trim(),
        apiKey: _apiKeyCtrl.text.trim(),
        wablasBaseUrl: baseUrl,
        wablasApiKey: apiKey,
        wablasSecKey: secKey,
        thermalPrinterKey: _thermalPrinterKey,
        thermalPrinterName: _thermalPrinterCtrl.text.trim(),
      );
      await service.testWebhook(config: tempConfig, phone: phone);
      if (mounted) {
        setState(() {
          _wablasTestResult = 'Pesan uji berhasil dikirim ke $phone.';
          _wablasTestSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _wablasTestResult = 'Gagal: $e';
          _wablasTestSuccess = false;
        });
      }
    } finally {
      if (mounted) setState(() => _testingWablas = false);
    }
  }

  // ── Save ────────────────────────────────────────────────────────────

  Future<void> _scanAndSelectThermalPrinter() async {
    setState(() => _scanningThermal = true);
    try {
      final service = ref.read(ticketPrinterServiceProvider);
      final printers = await service.scanUsbPrinters();
      if (!mounted) return;

      if (printers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada printer thermal USB yang terdeteksi')),
        );
        return;
      }

      final selected = await showDialog<TicketPrinterDevice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pilih Printer Thermal'),
          content: SizedBox(
            width: 420,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: printers.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = printers[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: p.address == null || p.address!.isEmpty
                      ? null
                      : Text(p.address!),
                  onTap: () => Navigator.of(ctx).pop(p),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      );

      if (selected == null || !mounted) return;
      setState(() {
        _thermalPrinterKey = selected.key;
        _thermalPrinterCtrl.text = selected.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal scan printer thermal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _scanningThermal = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final config = AppConfig(
      hikvisionIp: _hikIpCtrl.text.trim(),
      hikvisionUser: _hikUserCtrl.text.trim(),
      hikvisionPassword: _hikPassCtrl.text,
      hikvisionMac: _hikMacCtrl.text.trim(),
      serverUrl: _serverUrlCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      wablasBaseUrl: _wablasBaseUrlCtrl.text.trim(),
      wablasApiKey: _wablasApiKeyCtrl.text.trim(),
      wablasSecKey: _wablasSecKeyCtrl.text.trim(),
      thermalPrinterKey: _thermalPrinterKey,
      thermalPrinterName: _thermalPrinterCtrl.text.trim(),
    );

    await ref.read(configProvider.notifier).updateConfig(config);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  Future<void> _testThermalPrinter() async {
    if (_thermalPrinterKey.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih printer thermal dulu')),
      );
      return;
    }

    setState(() => _testingPrint = true);
    try {
      await ref.read(ticketPrinterServiceProvider).printTest(
            preferredPrinterKey: _thermalPrinterKey,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test print berhasil dikirim')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test print gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _testingPrint = false);
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  OutlineInputBorder? _errorBorder(String field) {
    final match = (field == 'ip' || field == 'creds')
        ? _hikErrorField == field
        : _serverErrorField == field;
    if (!match) return null;
    return const OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 2),
    );
  }

  Widget _testResultBanner(String result, bool success) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result,
              style: TextStyle(
                color: success ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(configProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (config) {
          if (!_fieldsPopulated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_fieldsPopulated) {
                _populateFields(config);
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hikvision ─────────────────────────────────
                  Text('Hikvision Reader',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hikIpCtrl,
                    decoration: InputDecoration(
                      labelText: 'IP Address',
                      hintText: '192.168.40.181',
                      border: const OutlineInputBorder(),
                      enabledBorder: _errorBorder('ip'),
                      focusedBorder: _errorBorder('ip'),
                      errorText: _hikErrorField == 'ip'
                          ? 'Cannot reach this IP'
                          : null,
                    ),
                    onChanged: (_) {
                      if (_hikErrorField != null) {
                        setState(() => _clearHikTestState());
                      }
                    },
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hikUserCtrl,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: const OutlineInputBorder(),
                      enabledBorder: _errorBorder('creds'),
                      focusedBorder: _errorBorder('creds'),
                      errorText: _hikErrorField == 'creds'
                          ? 'Check username'
                          : null,
                    ),
                    onChanged: (_) {
                      if (_hikErrorField != null) {
                        setState(() => _clearHikTestState());
                      }
                    },
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hikPassCtrl,
                    obscureText: _obscurePass,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      enabledBorder: _errorBorder('creds'),
                      focusedBorder: _errorBorder('creds'),
                      errorText: _hikErrorField == 'creds'
                          ? 'Check password'
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePass
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    onChanged: (_) {
                      if (_hikErrorField != null) {
                        setState(() => _clearHikTestState());
                      }
                    },
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hikMacCtrl,
                    decoration: const InputDecoration(
                      labelText: 'MAC Address',
                      hintText: '08:54:11:32:fe:5b',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_testingHik || _detectingHikIp)
                              ? null
                              : _autoDetectHikvisionIp,
                          icon: _detectingHikIp
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(_detectingHikIp
                              ? 'Mencari IP...'
                              : 'Deteksi Ulang Manual'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (_testingHik || _detectingHikIp)
                              ? null
                              : _testHikvision,
                          icon: _testingHik
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.lan),
                          label: Text(
                              _testingHik ? 'Testing...' : 'Test Connection'),
                        ),
                      ),
                    ],
                  ),
                  if (_hikTestResult != null) ...[
                    const SizedBox(height: 8),
                    _testResultBanner(_hikTestResult!, _hikTestSuccess!),
                  ],

                  const SizedBox(height: 32),

                  // ── Server ────────────────────────────────────
                  Text('Server',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _serverUrlCtrl,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'Default dari .env (BACKEND_URL) / lib/config/app_config.dart',
                      border: const OutlineInputBorder(),
                      enabledBorder: _errorBorder('url'),
                      focusedBorder: _errorBorder('url'),
                      errorText: _serverErrorField == 'url'
                          ? 'Cannot reach server'
                          : null,
                    ),
                    onChanged: (_) {
                      if (_serverErrorField != null) {
                        setState(() => _clearServerTestState());
                      }
                    },
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apiKeyCtrl,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      labelText: 'Desktop API Key',
                      hintText: 'Default dari .env (DESKTOP_API_KEY) / lib/config/app_config.dart',
                      border: const OutlineInputBorder(),
                      enabledBorder: _errorBorder('key'),
                      focusedBorder: _errorBorder('key'),
                      errorText: _serverErrorField == 'key'
                          ? 'Invalid API key'
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                    onChanged: (_) {
                      if (_serverErrorField != null) {
                        setState(() => _clearServerTestState());
                      }
                    },
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testingServer ? null : _testServer,
                      icon: _testingServer
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud),
                      label: Text(
                          _testingServer ? 'Testing...' : 'Test Connection'),
                    ),
                  ),
                  if (_serverTestResult != null) ...[
                    const SizedBox(height: 8),
                    _testResultBanner(
                        _serverTestResult!, _serverTestSuccess!),
                  ],

                  const SizedBox(height: 32),

                  Text('Wablas Webhook',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wablasBaseUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Wablas Base URL',
                      hintText: 'Default dari .env (WABLAS_BASE_URL) / lib/config/app_config.dart',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wablasApiKeyCtrl,
                    obscureText: _obscureWablasApiKey,
                    decoration: InputDecoration(
                      labelText: 'Wablas API Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureWablasApiKey
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                          () => _obscureWablasApiKey = !_obscureWablasApiKey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wablasSecKeyCtrl,
                    obscureText: _obscureWablasSecKey,
                    decoration: InputDecoration(
                      labelText: 'Wablas Secret Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureWablasSecKey
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                          () => _obscureWablasSecKey = !_obscureWablasSecKey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testingWablas ? null : _testWablas,
                      icon: _testingWablas
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(_testingWablas ? 'Mengirim...' : 'Test Webhook'),
                    ),
                  ),
                  if (_wablasTestResult != null) ...[
                    const SizedBox(height: 8),
                    _testResultBanner(_wablasTestResult!, _wablasTestSuccess!),
                  ],

                  const SizedBox(height: 32),

                  Text('Printer Thermal',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _thermalPrinterCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Printer Terpilih',
                      hintText: 'Belum ada printer dipilih',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _scanningThermal ? null : _scanAndSelectThermalPrinter,
                      icon: _scanningThermal
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.print),
                      label: Text(_scanningThermal
                          ? 'Mencari printer...'
                          : 'Cari Printer Thermal'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testingPrint ? null : _testThermalPrinter,
                      icon: _testingPrint
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.receipt_long),
                      label: Text(_testingPrint ? 'Mencetak test...' : 'Test Print'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
