// lib/modules/app_config.dart
// Simple INI-style config file reader/writer
// Stores config.ini next to the executable in release, or in the workspace root in debug

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AppConfig {
  static String? _configPath;
  static Map<String, String> _values = {};
  static bool enableTransparency = true;

  /// Initialize and load config from disk.
  /// Creates config.ini with defaults if it doesn't exist.
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        _configPath = p.join(Directory.current.path, 'config.ini');
      } else {
        final exeDir = p.dirname(Platform.resolvedExecutable);
        _configPath = p.join(exeDir, 'config.ini');
      }
      await _load();
    } catch (_) {
      _configPath = 'config.ini';
      await _load();
    }

    final defaultTransparency = _isWindows11OrNewer();
    final transparencyStr = get('enable_transparency', defaultValue: defaultTransparency ? 'true' : 'false');
    enableTransparency = transparencyStr == 'true';
    if (_values['enable_transparency'] == null) {
      await set('enable_transparency', transparencyStr);
    }
  }

  static bool _isWindows11OrNewer() {
    if (!Platform.isWindows) return false;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
      if (match != null) {
        final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        return buildNumber >= 22000;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> _load() async {
    try {
      final file = File(_configPath!);
      if (!file.existsSync()) {
        _values = {
          'language': 'vi',
          'theme': 'dark',
          'enable_transparency': 'true',
          'clean_c_files': 'true',
          'delete_source': 'false',
          'language_level': '3',
          'directive_boundscheck': 'false',
          'directive_wraparound': 'false',
          'directive_initializedcheck': 'false',
          'directive_nonecheck': 'false',
        };
        await _save();
        return;
      }

      _values = {};
      final lines = file.readAsLinesSync();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('[')) continue;
        final eqIdx = trimmed.indexOf('=');
        if (eqIdx > 0) {
          final key = trimmed.substring(0, eqIdx).trim();
          final value = trimmed.substring(eqIdx + 1).trim();
          _values[key] = value;
        }
      }
    } catch (_) {
      // Fallback defaults on read error
      _values = {
        'language': 'vi',
        'theme': 'dark',
        'enable_transparency': 'true',
        'clean_c_files': 'true',
        'delete_source': 'false',
        'language_level': '3',
        'directive_boundscheck': 'false',
        'directive_wraparound': 'false',
        'directive_initializedcheck': 'false',
        'directive_nonecheck': 'false',
      };
    }
  }

  static Future<void> _save() async {
    try {
      if (_configPath == null) return;
      final file = File(_configPath!);
      final parent = file.parent;
      if (!parent.existsSync()) {
        parent.createSync(recursive: true);
      }
      final buffer = StringBuffer();
      buffer.writeln('[app]');
      _values.forEach((k, v) => buffer.writeln('$k=$v'));
      file.writeAsStringSync(buffer.toString());
    } catch (_) {}
  }

  /// Get a config value by key, with optional default.
  static String get(String key, {String defaultValue = ''}) {
    return _values[key] ?? defaultValue;
  }

  /// Get boolean config value
  static bool getBool(String key, {bool defaultValue = false}) {
    final val = _values[key];
    if (val == null) return defaultValue;
    return val.toLowerCase() == 'true';
  }

  /// Set a config value and immediately persist to disk.
  static Future<void> set(String key, String value) async {
    _values[key] = value;
    await _save();
  }
}
