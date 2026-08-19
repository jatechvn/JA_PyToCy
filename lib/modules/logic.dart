// lib/modules/logic.dart
// Core business logic coordinator for Python to Cython compilation

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'constants.dart';
import 'app_config.dart';
import 'utils.dart';

final _logger = Logger('Logic');

class ConversionEntry {
  final String filePath;
  final String fileName;
  final String directoryPath;
  final int sizeBytes;
  String status; // 'pending', 'compiling', 'success', 'failed'
  String details; // duration, size reduction, error message
  int? compiledSizeBytes;
  Duration? duration;

  ConversionEntry({
    required this.filePath,
    required this.fileName,
    required this.directoryPath,
    required this.sizeBytes,
    this.status = 'pending',
    this.details = '',
    this.compiledSizeBytes,
    this.duration,
  });

  String get sizeStr => formatFileSize(sizeBytes);
  String get compiledSizeStr => compiledSizeBytes != null ? formatFileSize(compiledSizeBytes!) : '-';
  String get speedupStr => duration != null ? formatDuration(duration!) : '-';
}

class EnvironmentStatus {
  bool pythonAvailable = false;
  bool cythonAvailable = false;
  bool compilerAvailable = false;
  String pythonVersion = '';
  String cythonVersion = '';
  String compilerInfo = '';
}

class CompilerLogic {
  final List<ConversionEntry> queue = [];
  final EnvironmentStatus env = EnvironmentStatus();
  
  // Real-time console logs stream
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  // Status updates stream
  final _statusController = StreamController<void>.broadcast();
  Stream<void> get statusStream => _statusController.stream;

  bool isCompiling = false;

  void dispose() {
    _logController.close();
    _statusController.close();
  }

  void appendLog(String log) {
    _logController.add(log);
  }

  void notifyStatusChange() {
    _statusController.add(null);
  }

  /// Check system environment for Python, Cython, and C++ Compiler
  Future<EnvironmentStatus> checkEnvironment() async {
    _logger.info('Checking environment...');
    
    // 1. Check Python
    try {
      final pyResult = await Process.run('python', ['--version']);
      if (pyResult.exitCode == 0) {
        env.pythonAvailable = true;
        env.pythonVersion = (pyResult.stdout as String).trim();
        if (env.pythonVersion.isEmpty) {
          env.pythonVersion = (pyResult.stderr as String).trim();
        }
      } else {
        env.pythonAvailable = false;
        env.pythonVersion = '';
      }
    } catch (_) {
      env.pythonAvailable = false;
      env.pythonVersion = '';
    }

    // 2. Check Cython
    if (env.pythonAvailable) {
      try {
        final cyResult = await Process.run('python', [
          '-c',
          'import Cython; print(Cython.__version__)'
        ]);
        if (cyResult.exitCode == 0) {
          env.cythonAvailable = true;
          env.cythonVersion = (cyResult.stdout as String).trim();
        } else {
          env.cythonAvailable = false;
          env.cythonVersion = '';
        }
      } catch (_) {
        env.cythonAvailable = false;
        env.cythonVersion = '';
      }
    } else {
      env.cythonAvailable = false;
      env.cythonVersion = '';
    }

    // 3. Check C Compiler
    // Run a basic check on Windows (cl / gcc)
    try {
      if (Platform.isWindows) {
        // Test compile a trivial line with setuptools distutils compiler check
        // Or check if MSVC registry or vswhere exists
        final vsWhereFile = File('C:\\Program Files (x86)\\Microsoft Visual Studio\\Installer\\vswhere.exe');
        if (vsWhereFile.existsSync()) {
          env.compilerAvailable = true;
          env.compilerInfo = 'MSVC (Build Tools / Visual Studio)';
        } else {
          // Fallback check: gcc
          final gccResult = await Process.run('gcc', ['--version']);
          if (gccResult.exitCode == 0) {
            env.compilerAvailable = true;
            env.compilerInfo = 'MinGW / GCC';
          } else {
            env.compilerAvailable = false;
            env.compilerInfo = '';
          }
        }
      } else {
        // macOS / Linux
        final gccResult = await Process.run('gcc', ['--version']);
        if (gccResult.exitCode == 0) {
          env.compilerAvailable = true;
          env.compilerInfo = 'GCC';
        } else {
          final clangResult = await Process.run('clang', ['--version']);
          if (clangResult.exitCode == 0) {
            env.compilerAvailable = true;
            env.compilerInfo = 'Clang';
          } else {
            env.compilerAvailable = false;
            env.compilerInfo = '';
          }
        }
      }
    } catch (_) {
      env.compilerAvailable = false;
      env.compilerInfo = '';
    }

    _logger.info('Env check completed: python=${env.pythonAvailable}, cython=${env.cythonAvailable}, compiler=${env.compilerAvailable}');
    notifyStatusChange();
    return env;
  }

  /// Install Cython using pip
  Future<bool> installCython() async {
    appendLog('\n>>> Running: pip install cython...\n');
    try {
      final process = await Process.start('python', ['-m', 'pip', 'install', 'cython']);
      
      process.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
        appendLog(data);
      });
      process.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((data) {
        appendLog(data);
      });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        appendLog('\n>>> Cython installed successfully!\n');
        await checkEnvironment();
        return true;
      } else {
        appendLog('\n>>> pip install cython failed with exit code $exitCode\n');
        return false;
      }
    } catch (e) {
      appendLog('\n>>> Error starting pip install: $e\n');
      return false;
    }
  }

  /// Add single python file to the conversion queue
  void addFile(String filePath) {
    final fileName = p.basename(filePath);
    if (fileName.toLowerCase() == '__init__.py') return;

    final file = File(filePath);
    if (!file.existsSync() || p.extension(filePath) != '.py') return;
    
    // Avoid duplicates
    if (queue.any((e) => e.filePath == filePath)) return;

    final entry = ConversionEntry(
      filePath: normalizePath(filePath),
      fileName: p.basename(filePath),
      directoryPath: normalizePath(p.dirname(filePath)),
      sizeBytes: file.lengthSync(),
    );

    queue.add(entry);
    notifyStatusChange();
  }

  /// Recursively scan folder for python files and add them to the queue
  Future<void> addDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return;

    try {
      final list = dir.listSync(recursive: true);
      for (final entity in list) {
        if (entity is File && p.extension(entity.path) == '.py') {
          addFile(entity.path);
        }
      }
    } catch (e) {
      _logger.severe('Error scanning directory $dirPath: $e');
    }
  }

  /// Clear the queue list
  void clearQueue() {
    if (isCompiling) return;
    queue.clear();
    notifyStatusChange();
  }

  /// Start compiling the entire queue one by one
  Future<void> compileAll() async {
    if (isCompiling || queue.isEmpty) return;
    isCompiling = true;
    notifyStatusChange();

    appendLog('\n========================================\n');
    appendLog('  STARTING CYTHON BATCH COMPILATION\n');
    appendLog('========================================\n\n');

    final cleanCFiles = AppConfig.getBool(keyCleanCFiles, defaultValue: true);
    final deleteSource = AppConfig.getBool(keyDeleteSource, defaultValue: false);
    final languageLevel = AppConfig.get(keyLanguageLevel, defaultValue: '3');

    // Build directives map
    final directives = {
      'language_level': languageLevel,
      'boundscheck': AppConfig.getBool(keyDirectiveBoundsCheck, defaultValue: false),
      'wraparound': AppConfig.getBool(keyDirectiveWrapAround, defaultValue: false),
      'initializedcheck': AppConfig.getBool(keyDirectiveInitializedCheck, defaultValue: false),
      'nonecheck': AppConfig.getBool(keyDirectiveNoneCheck, defaultValue: false),
    };

    final List<File> compiledBinaries = [];
    final List<ConversionEntry> successfulEntries = [];
    bool hasError = false;

    for (int i = 0; i < queue.length; i++) {
      final entry = queue[i];
      if (entry.status == 'success') continue; // Skip already compiled files

      entry.status = 'compiling';
      notifyStatusChange();

      appendLog('[${i + 1}/${queue.length}] Compiling: ${entry.fileName}...\n');
      final startTime = DateTime.now();

      // Compile file (but do NOT delete source file yet)
      final success = await _compileSingleFile(entry, directives, cleanCFiles);
      final endTime = DateTime.now();
      entry.duration = endTime.difference(startTime);

      if (success) {
        entry.status = 'success';
        successfulEntries.add(entry);
        
        // Scan for generated binary file to measure compiled size and track for rollback
        final binaryFile = _findCompiledBinary(entry.directoryPath, entry.fileName);
        if (binaryFile != null) {
          compiledBinaries.add(binaryFile);
          entry.compiledSizeBytes = binaryFile.lengthSync();
          final reduction = ((1.0 - (entry.compiledSizeBytes! / entry.sizeBytes)) * 100).toStringAsFixed(1);
          entry.details = 'Time: ${formatDuration(entry.duration!)}, Size reduction: $reduction%';
        } else {
          entry.details = 'Time: ${formatDuration(entry.duration!)}';
        }
      } else {
        entry.status = 'failed';
        entry.details = 'Compilation failed';
        hasError = true;
        notifyStatusChange();
        appendLog('\n>>> ERROR: Compilation failed for ${entry.fileName}. Aborting batch compilation!\n');
        break; // Abort compiling remaining files
      }

      notifyStatusChange();
      appendLog('\n----------------------------------------\n\n');
    }

    if (!hasError) {
      // All compiled successfully, now create backup and delete source files if checked
      if (deleteSource && successfulEntries.isNotEmpty) {
        appendLog('>>> All compilations succeeded. Backing up source files (.py) before deletion...\n');
        
        final Map<String, List<String>> dirToFiles = {};
        for (final entry in successfulEntries) {
          final file = File(entry.filePath);
          if (file.existsSync()) {
            dirToFiles.putIfAbsent(entry.directoryPath, () => []).add(entry.filePath);
          }
        }

        // Create backup zip for each directory
        for (final entry in dirToFiles.entries) {
          final dirPath = entry.key;
          final filePaths = entry.value;
          if (filePaths.isNotEmpty) {
            await _createBackupZip(dirPath, filePaths);
          }
        }

        // Delete source .py files
        appendLog('>>> Deleting original source files (.py)...\n');
        for (final entry in successfulEntries) {
          final pyFile = File(entry.filePath);
          _safeDelete(pyFile);
        }
        appendLog('>>> Source file deletion completed successfully.\n');
      }
      
      appendLog('========================================\n');
      appendLog('  COMPILATION WORKFLOW COMPLETED (SUCCESS)\n');
      appendLog('========================================\n');
    } else {
      // Rollback: delete all newly compiled binaries in this run and reset entry statuses
      appendLog('\n>>> ROLLBACK: Compilations failed. Reverting all changes to preserve workspace consistency...\n');
      
      for (final binary in compiledBinaries) {
        appendLog('>>> Removing compiled binary: ${p.basename(binary.path)}\n');
        _safeDelete(binary);
      }

      // Reset successful entries back to pending
      for (final entry in successfulEntries) {
        entry.status = 'pending';
        entry.details = 'Rolled back due to batch failure';
        entry.compiledSizeBytes = null;
        entry.duration = null;
      }

      notifyStatusChange();
      appendLog('>>> Rollback completed. Original source files and binaries are unchanged.\n');
      appendLog('========================================\n');
      appendLog('  COMPILATION WORKFLOW ABORTED (FAILED)\n');
      appendLog('========================================\n');
    }

    isCompiling = false;
    notifyStatusChange();
  }

  /// Compile a single file using setuptools
  Future<bool> _compileSingleFile(
    ConversionEntry entry,
    Map<String, dynamic> directives,
    bool cleanCFiles,
  ) async {
    // Check if the destination binary is locked by another process
    final existingBinary = _findCompiledBinary(entry.directoryPath, entry.fileName);
    if (existingBinary != null) {
      try {
        final access = existingBinary.openSync(mode: FileMode.append);
        access.closeSync();
      } catch (e) {
        appendLog('\n>>> ERROR: File is locked by another process!\n');
        appendLog('>>> Path: ${existingBinary.path}\n');
        appendLog('>>> LỖI: Tệp tin đang bị khóa bởi tiến trình khác!\n');
        appendLog('>>> Vui lòng đóng ứng dụng đang sử dụng tệp này (ví dụ: JA_Voice_Tool) và thử lại.\n\n');
        _logger.severe('File is locked by another process: ${existingBinary.path}. Exception: $e');
        return false;
      }
    }

    // Generate a unique temporary setup script
    final setupFileName = 'setup_temp_${DateTime.now().millisecondsSinceEpoch}.py';
    final setupFilePath = p.join(entry.directoryPath, setupFileName);
    final setupFile = File(setupFilePath);

    // Setup script content
    final directivesStr = directives.entries
        .map((e) => "        '${e.key}': ${e.value == true ? 'True' : e.value == false ? 'False' : "'${e.value}'"},")
        .join('\n');

    final moduleName = p.basenameWithoutExtension(entry.fileName);
    final setupContent = '''
import sys
from setuptools import setup, Extension
from Cython.Build import cythonize

directives = {
$directivesStr
}

setup(
    ext_modules = cythonize(
        Extension("$moduleName", sources=["${entry.fileName}"]),
        compiler_directives=directives,
    )
)
''';

    final accumulatedLog = StringBuffer();

    try {
      setupFile.writeAsStringSync(setupContent);
      _logger.info('Wrote temporary setup file: $setupFilePath');

      // Start python subprocess
      final process = await Process.start(
        'python',
        [setupFileName, 'build_ext', '--inplace'],
        workingDirectory: entry.directoryPath,
      );

      // Listen to streams and wait for them to finish
      final stdoutFuture = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).forEach((data) {
        appendLog(data);
        accumulatedLog.write(data);
      });
      
      final stderrFuture = process.stderr.transform(const Utf8Decoder(allowMalformed: true)).forEach((data) {
        appendLog(data);
        accumulatedLog.write(data);
      });

      final results = await Future.wait([
        process.exitCode,
        stdoutFuture,
        stderrFuture,
      ]);
      
      final exitCode = results[0] as int;
      
      // Cleanup setup file and build directory immediately
      _safeDelete(setupFile);
      final buildDir = Directory(p.join(entry.directoryPath, 'build'));
      _safeDeleteDir(buildDir);

      if (exitCode == 0) {
        appendLog('>>> Compile success: ${entry.fileName}\n');

        _logger.info('=== COMPILATION SUCCESS: ${entry.fileName} ===');
        _logger.info('Working Directory: ${entry.directoryPath}');
        _logger.info('Compiler Output:\n$accumulatedLog');
        _logger.info('=============================================');

        // Cleanup intermediate .c file if checked
        if (cleanCFiles) {
          final cFileName = p.setExtension(entry.fileName, '.c');
          final cFile = File(p.join(entry.directoryPath, cFileName));
          _safeDelete(cFile);
        }



        return true;
      } else {
        appendLog('>>> Compile failed: ${entry.fileName} (exit code: $exitCode)\n');

        _logger.severe('=== COMPILATION FAILED: ${entry.fileName} ===');
        _logger.severe('Working Directory: ${entry.directoryPath}');
        _logger.severe('Compiler Output:\n$accumulatedLog');
        _logger.severe('=============================================');

        return false;
      }
    } catch (e) {
      appendLog('>>> Execution error: $e\n');
      _safeDelete(setupFile);
      return false;
    }
  }

  /// Create a zip backup of the .py files in the queue
  Future<bool> _createBackupZip(String dirPath, List<String> filePaths) async {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    
    final parentDir = p.dirname(dirPath);
    final dirName = p.basename(dirPath);
    final zipName = '${dirName}_backup_$timestamp.zip';
    
    // If the parent directory is empty or same as dirPath, fallback to dirPath
    final zipPath = (parentDir == dirPath || parentDir.isEmpty)
        ? p.join(dirPath, zipName)
        : p.join(parentDir, zipName);

    try {
      final args = [
        '-c',
        'import zipfile, sys, os; '
        'zipf = zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED); '
        '[zipf.write(f, os.path.basename(f)) for f in sys.argv[2:]]; '
        'zipf.close()',
        zipPath,
        ...filePaths,
      ];

      final process = await Process.run('python', args);
      if (process.exitCode == 0) {
        appendLog('>>> Created source backup: $zipName\n');
        _logger.info('Created backup zip: $zipPath');
        return true;
      } else {
        appendLog('>>> ERROR creating backup zip: ${process.stderr}\n');
        _logger.severe('Failed to create backup zip: ${process.stderr}');
        return false;
      }
    } catch (e) {
      appendLog('>>> ERROR starting backup: $e\n');
      _logger.severe('Exception creating backup zip: $e');
      return false;
    }
  }

  /// Find compiled binary (.pyd or .so) matching the module name
  File? _findCompiledBinary(String dirPath, String pyFileName) {
    final moduleName = p.basenameWithoutExtension(pyFileName);
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;

    try {
      final list = dir.listSync();
      for (final entity in list) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.startsWith(moduleName)) {
            final ext = p.extension(entity.path).toLowerCase();
            if (ext == '.pyd' || ext == '.so') {
              return entity;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void _safeDelete(File file) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      _logger.warning('Failed to delete file ${file.path}: $e');
    }
  }

  void _safeDeleteDir(Directory dir) {
    try {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (e) {
      _logger.warning('Failed to delete directory ${dir.path}: $e');
    }
  }
}
