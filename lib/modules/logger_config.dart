// lib/modules/logger_config.dart
// Centralized logger configuration for JA_PyToCy

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

IOSink? _logFileSink;

void setupLogger() {
  Logger.root.level = Level.ALL;

  // Create logs directory
  final logDir = Directory(p.join(Directory.current.path, 'logs'));
  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }

  // Daily log file
  final now = DateTime.now();
  final logFileName = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.log';
  final logFile = File(p.join(logDir.path, logFileName));
  _logFileSink = logFile.openWrite(mode: FileMode.append);

  Logger.root.onRecord.listen((record) {
    final message = '[${record.time}] ${record.level.name}: ${record.loggerName} - ${record.message}';
    // Console output
    // ignore: avoid_print
    print(message);
    // File output
    _logFileSink?.writeln(message);
  });
}

void disposeLogger() {
  _logFileSink?.close();
}
