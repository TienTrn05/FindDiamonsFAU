class DownloadedMap {
  const DownloadedMap({
    required this.path,
    required this.filename,
    required this.bytes,
  });

  final String path;
  final String filename;
  final int bytes;
}

class MapDownloadProgress {
  const MapDownloadProgress(this.received, this.total);

  final int received;
  final int? total;

  double? get fraction =>
      total == null || total! <= 0 ? null : (received / total!).clamp(0.0, 1.0);
}
