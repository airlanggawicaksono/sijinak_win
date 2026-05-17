import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';

import 'ui/screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    final text = details.exceptionAsString();
    final isWindowsAltKeyNoise =
        text.contains('Attempted to send a key down event when no keys are in keysPressed');
    final isEmptyJsonNoise =
        text.contains('Unable to parse JSON message') &&
            text.contains('The document is empty');

    if (isWindowsAltKeyNoise || isEmptyJsonNoise) {
      return;
    }

    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    final text = error.toString();
    final isWindowsAltKeyNoise =
        text.contains('Attempted to send a key down event when no keys are in keysPressed');
    final isEmptyJsonNoise =
        text.contains('Unable to parse JSON message') &&
            text.contains('The document is empty');

    if (isWindowsAltKeyNoise || isEmptyJsonNoise) {
      return true;
    }
    return false;
  };

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(900, 600),
    minimumSize: Size(700, 500),
    title: 'Sijinak',
    center: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: SijinakApp()));
}

class SijinakApp extends StatelessWidget {
  const SijinakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sijinak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AppShell(),
    );
  }
}
