class Sensor {
  final String id;
  final String name;
  final String type; // 'temperature', 'humidity', 'smoke', 'wind'
  final double lat;
  final double lon;
  final double value;
  final String unit;
  final String status; // 'active', 'offline', 'alert'
  final DateTime lastReading;

  Sensor({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lon,
    required this.value,
    required this.unit,
    required this.status,
    required this.lastReading,
  });

  String get formattedValue => '${value.toStringAsFixed(1)} $unit';

  String get typeLabel {
    switch (type) {
      case 'temperature':
        return 'Temperatura';
      case 'humidity':
        return 'Humedad';
      case 'smoke':
        return 'Humo (PPM)';
      case 'wind':
        return 'Viento';
      default:
        return type;
    }
  }

  String get typeIcon {
    switch (type) {
      case 'temperature':
        return '🌡️';
      case 'humidity':
        return '💧';
      case 'smoke':
        return '💨';
      case 'wind':
        return '🌬️';
      default:
        return '📡';
    }
  }
}
