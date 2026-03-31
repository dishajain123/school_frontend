import 'dart:io';
import 'package:path/path.dart' as p;

class FileUtils {
  FileUtils._();

  /// Returns a human-readable file size string.
  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Returns the MIME type based on file extension.
  static String mimeType(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    const map = <String, String>{
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  /// Returns true if the file is an image.
  static bool isImage(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
  }

  /// Returns true if the file is a PDF.
  static bool isPdf(String path) =>
      p.extension(path).toLowerCase() == '.pdf';

  /// Returns the file name without directory.
  static String fileName(String path) => p.basename(path);

  /// Returns the file extension without the dot.
  static String extension(String path) =>
      p.extension(path).toLowerCase().replaceAll('.', '');

  /// Returns true if file size is within the allowed limit.
  static bool isWithinSizeLimit(File file, int maxBytes) =>
      file.lengthSync() <= maxBytes;
}