
class Alert {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final double lat;
  final double lon;
  final String level; // 'critical', 'warning'
  final String source;
  final String zoneLabel;
  final double frp;
  final String confidence;
  final String sensor;
  final String dispatchedBy;
  bool reinforcementsRequested;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.lat,
    required this.lon,
    required this.level,
    required this.source,
    required this.zoneLabel,
    this.frp = 0,
    this.confidence = '',
    this.sensor = '',
    this.dispatchedBy = '',
    this.reinforcementsRequested = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    return 'Hace ${diff.inDays}d';
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get coordsFormatted =>
      '${lat.toStringAsFixed(4)}°, ${lon.toStringAsFixed(4)}°';

  String get frpLabel {
    if (frp > 50) return 'Alta (${frp.toStringAsFixed(1)} MW)';
    if (frp > 10) return 'Media (${frp.toStringAsFixed(1)} MW)';
    return 'Baja (${frp.toStringAsFixed(1)} MW)';
  }
}
