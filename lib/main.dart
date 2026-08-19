// lib/main.dart
// Program entry point for JA PyToCy Converter
// Transparent blur window with Light/Dark/Auto theme + multi-language support

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'modules/constants.dart';
import 'modules/logger_config.dart';
import 'modules/logic.dart';
import 'modules/app_config.dart';
import 'modules/i18n.dart';
import 'modules/ui/styles.dart';
import 'modules/ui/main_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  setupLogger();

  // Load config from disk
  await AppConfig.initialize();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Initialize flutter_acrylic for transparent blur
  await Window.initialize();

  // Configure window
  const windowOptions = WindowOptions(
    size: Size(1280, 720),
    minimumSize: Size(960, 540),
    title: '$appName  v$appVersion',
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    try {
      await windowManager.setAlignment(Alignment.center);
    } catch (_) {}
  });

  // Apply acrylic/mica blur effect if enabled
  if (AppConfig.enableTransparency) {
    try {
      await Window.setEffect(
        effect: WindowEffect.acrylic,
        color: const Color(0x00000000), // fully transparent base
      );
    } catch (_) {
      try {
        await Window.setEffect(
          effect: WindowEffect.mica,
          color: const Color(0x00000000),
        );
      } catch (_) {}
    }
  } else {
    try {
      await Window.setEffect(
        effect: WindowEffect.disabled,
      );
    } catch (_) {}
  }

  // Initialize Compiler Logic
  final compilerLogic = CompilerLogic();

  // Restore saved language and theme mode
  final savedLang = AppLanguageExt.fromCode(AppConfig.get('language', defaultValue: 'vi'));
  final savedThemeStr = AppConfig.get('theme', defaultValue: 'dark');
  final savedThemeMode = AppThemeModeExt.fromCode(savedThemeStr);

  runApp(JaPyToCyApp(
    logic: compilerLogic,
    initialLanguage: savedLang,
    initialThemeMode: savedThemeMode,
  ));
}

class JaPyToCyApp extends StatefulWidget {
  final CompilerLogic logic;
  final AppLanguage initialLanguage;
  final AppThemeMode initialThemeMode;

  const JaPyToCyApp({
    super.key,
    required this.logic,
    required this.initialLanguage,
    required this.initialThemeMode,
  });

  @override
  State<JaPyToCyApp> createState() => _JaPyToCyAppState();
}

class _JaPyToCyAppState extends State<JaPyToCyApp> {
  late final ThemeNotifier _themeNotifier;
  late final LanguageNotifier _languageNotifier;

  @override
  void initState() {
    super.initState();
    _languageNotifier = LanguageNotifier(widget.initialLanguage);
    
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    _themeNotifier = ThemeNotifier(widget.initialThemeMode, platformBrightness);
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    _languageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageProvider(
      notifier: _languageNotifier,
      child: ListenableBuilder(
        listenable: Listenable.merge([_themeNotifier, _languageNotifier]),
        builder: (context, _) {
          return MaterialApp(
            title: '$appName  v$appVersion',
            debugShowCheckedModeBanner: false,
            theme: buildThemeData(_themeNotifier.colors),
            home: ThemeReveal(
              themeNotifier: _themeNotifier,
              child: MainWindow(
                logic: widget.logic,
                themeNotifier: _themeNotifier,
                languageNotifier: _languageNotifier,
              ),
            ),
          );
        },
      ),
    );
  }
}
