import 'dart:math';
import 'alert.dart';

class Drone {
  final String id;
  final String name;
  final String type;
  final double batteryLevel;
  final double lat;
  final double lon;
  final String status; // 'available', 'deployed', 'maintenance'
  final String cameraType;
  final int maxSpeedKmh;

  Drone({
    required this.id,
    required this.name,
    required this.type,
    required this.batteryLevel,
    required this.lat,
    required this.lon,
    required this.status,
    this.cameraType = 'Térmica IR',
    this.maxSpeedKmh = 80,
  });

  /// Haversine distance in km
  double distanceTo(double targetLat, double targetLon) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(targetLat - lat);
    final dLon = _toRadians(targetLon - lon);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat)) *
            cos(_toRadians(targetLat)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Estimated flight time in minutes
  int estimatedMinutesTo(double targetLat, double targetLon) {
    final dist = distanceTo(targetLat, targetLon);
    return (dist / maxSpeedKmh * 60).ceil();
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

class DeployedDrone {
  final Drone drone;
  final Alert targetAlert;
  final DateTime deployedAt;

  DeployedDrone({
    required this.drone,
    required this.targetAlert,
    required this.deployedAt,
  });
}
