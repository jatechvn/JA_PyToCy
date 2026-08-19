// lib/modules/utils.dart
// Shared utility helper functions for JA_PyToCy

import 'package:path/path.dart' as p;

/// Normalize path separators for the host OS
String normalizePath(String path) {
  return p.normalize(path);
}

/// Format file size in human-readable format
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

/// Format duration to readable string
String formatDuration(Duration d) {
  if (d.inMilliseconds < 1000) {
    return '${d.inMilliseconds}ms';
  }
  return '${(d.inMilliseconds / 1000).toStringAsFixed(1)}s';
}
