import 'dart:math';
import '../models/alert.dart';
import '../models/drone.dart';
import '../models/sensor.dart';

import 'package:flutter/foundation.dart';

/// Service that provides all data for the dispatcher app.
/// Alerts come ONLY from the platform (simulated dispatch from dashboard).
/// Drones and sensors are simulated IoT endpoints.
class DispatcherService {
  static final _random = Random();
  
  static final ValueNotifier<List<DeployedDrone>> deployedDronesNotifier = ValueNotifier([]);

  static void deployDrone(Drone drone, Alert targetAlert) {
    final current = List<DeployedDrone>.from(deployedDronesNotifier.value);
    current.add(DeployedDrone(drone: drone, targetAlert: targetAlert, deployedAt: DateTime.now()));
    deployedDronesNotifier.value = current;
  }

  // ─── ALERTS (dispatched from dashboard platform) ───
  static List<Alert> getDispatchedAlerts() {
    final now = DateTime.now();
    return [
      Alert(
        id: 'DSP-001',
        title: 'Incendio Forestal — Parque Tunari',
        description:
            'Alerta despachada desde plataforma AlertaCBBA. Fuego detectado en la zona norte del Parque Nacional Tunari. Nivel de propagación alto. Se requiere intervención inmediata.',
        date: now.subtract(const Duration(minutes: 12)),
        lat: -17.3500,
        lon: -66.1500,
        level: 'critical',
        source: 'AlertaCBBA Platform',
        zoneLabel: '🚨 Cochabamba — Crítico',
      ),
      Alert(
        id: 'DSP-002',
        title: 'Incendio Pastizal — Sacaba',
        description:
            'Alerta despachada desde plataforma AlertaCBBA. Quema de pastizal en zona periurbana de Sacaba con riesgo de propagación a viviendas cercanas. Vientos fuertes del sur.',
        date: now.subtract(const Duration(minutes: 47)),
        lat: -17.4000,
        lon: -66.0400,
        level: 'critical',
        source: 'AlertaCBBA Platform',
        zoneLabel: '🚨 Cochabamba — Crítico',
      ),
      Alert(
        id: 'DSP-003',
        title: 'Quema Agrícola Descontrolada — Quillacollo',
        description:
            'Alerta despachada desde plataforma AlertaCBBA. Chaqueo descontrolado en zona agrícola. Humo visible en imágenes satelitales NASA FIRMS.',
        date: now.subtract(const Duration(hours: 2, minutes: 15)),
        lat: -17.3900,
        lon: -66.2800,
        level: 'warning',
        source: 'AlertaCBBA Platform',
        zoneLabel: '⚠️ Cochabamba — Advertencia',
      ),
    ];
  }

  // ─── DRONES (simulated fleet) ───
  static List<Drone> getAvailableDrones() {
    return [
      Drone(
        id: 'DRN-ALPHA',
        name: 'Explorador Alpha',
        type: 'Reconocimiento',
        batteryLevel: 94,
        lat: -17.3800,
        lon: -66.1600,
        status: 'available',
        cameraType: 'Térmica FLIR + RGB 4K',
        maxSpeedKmh: 85,
      ),
      Drone(
        id: 'DRN-BETA',
        name: 'Táctico Beta',
        type: 'Vigilancia',
        batteryLevel: 78,
        lat: -17.4100,
        lon: -66.1000,
        status: 'available',
        cameraType: 'Multispectral + Lidar',
        maxSpeedKmh: 72,
      ),
      Drone(
        id: 'DRN-GAMMA',
        name: 'Pesado Gamma',
        type: 'Carga',
        batteryLevel: 62,
        lat: -17.3600,
        lon: -66.2200,
        status: 'available',
        cameraType: 'Térmica IR',
        maxSpeedKmh: 55,
      ),
      Drone(
        id: 'DRN-DELTA',
        name: 'Centinela Delta',
        type: 'Reconocimiento',
        batteryLevel: 15,
        lat: -17.4300,
        lon: -66.1800,
        status: 'maintenance',
        cameraType: 'RGB 4K',
        maxSpeedKmh: 90,
      ),
    ];
  }

  // ─── SENSORS (simulated IoT near an alert) ───
  static List<Sensor> getSensorsNear(double lat, double lon) {
    final now = DateTime.now();
    // Generate realistic sensor readings near the alert
    return [
      Sensor(
        id: 'SENS-T01',
        name: 'Temp. Ambiental NE',
        type: 'temperature',
        lat: lat + 0.005,
        lon: lon + 0.008,
        value: 38.0 + _random.nextDouble() * 12,
        unit: '°C',
        status: 'alert',
        lastReading: now.subtract(Duration(seconds: _random.nextInt(120))),
      ),
      Sensor(
        id: 'SENS-H01',
        name: 'Humedad Relativa NE',
        type: 'humidity',
        lat: lat + 0.005,
        lon: lon + 0.008,
        value: 12.0 + _random.nextDouble() * 15,
        unit: '%',
        status: 'alert',
        lastReading: now.subtract(Duration(seconds: _random.nextInt(120))),
      ),
      Sensor(
        id: 'SENS-S01',
        name: 'Detector Humo SO',
        type: 'smoke',
        lat: lat - 0.004,
        lon: lon - 0.006,
        value: 180.0 + _random.nextDouble() * 320,
        unit: 'ppm',
        status: 'alert',
        lastReading: now.subtract(Duration(seconds: _random.nextInt(60))),
      ),
      Sensor(
        id: 'SENS-W01',
        name: 'Anemómetro Sur',
        type: 'wind',
        lat: lat - 0.006,
        lon: lon + 0.003,
        value: 15.0 + _random.nextDouble() * 30,
        unit: 'km/h',
        status: 'active',
        lastReading: now.subtract(Duration(seconds: _random.nextInt(90))),
      ),
    ];
  }
}
