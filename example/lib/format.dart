/// Formats a byte count as a human-readable string (e.g. `1.5 MB`).
///
/// Shared across the case files so the formatting stays consistent.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final precision = size >= 100 || unit == 0 ? 0 : 1;
  return '${size.toStringAsFixed(precision)} ${units[unit]}';
}
