import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert.dart';
import '../models/guard.dart';

/// Service that listens to Firebase Firestore for dispatched alerts.
/// Alerts are written by the web platform and read in real-time by this app.
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of URGENT alerts (sent by the platform operator as emergencies)
  Stream<List<Alert>> getUrgentAlerts() {
    return _firestore
        .collection('alerts')
        .where('type', isEqualTo: 'urgente')
        .orderBy('dispatched_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final d = doc.data();
              return Alert(
                id: doc.id,
                title: _buildTitle(d),
                description: _buildDescription(d),
                date: DateTime.tryParse(d['dispatched_at'] ?? '') ?? DateTime.now(),
                lat: (d['lat'] as num?)?.toDouble() ?? 0,
                lon: (d['lon'] as num?)?.toDouble() ?? 0,
                level: 'critical',
                source: d['sensor'] ?? 'FIRMS',
                zoneLabel: '🚨 ${d['region'] ?? 'Bolivia'} — Urgente',
                frp: (d['frp'] as num?)?.toDouble() ?? 0,
                confidence: d['confidence'] ?? '',
                sensor: d['sensor'] ?? '',
                dispatchedBy: d['dispatched_by'] ?? 'Operador',
              );
            }).toList());
  }

  /// Stream of REVIEW alerts (for routine patrol check)
  Stream<List<Alert>> getReviewAlerts() {
    return _firestore
        .collection('alerts')
        .where('type', isEqualTo: 'revision')
        .orderBy('dispatched_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final d = doc.data();
              return Alert(
                id: doc.id,
                title: _buildTitle(d),
                description: _buildDescription(d),
                date: DateTime.tryParse(d['dispatched_at'] ?? '') ?? DateTime.now(),
                lat: (d['lat'] as num?)?.toDouble() ?? 0,
                lon: (d['lon'] as num?)?.toDouble() ?? 0,
                level: 'warning',
                source: d['sensor'] ?? 'FIRMS',
                zoneLabel: '📋 ${d['region'] ?? 'Bolivia'} — Revisión',
                frp: (d['frp'] as num?)?.toDouble() ?? 0,
                confidence: d['confidence'] ?? '',
                sensor: d['sensor'] ?? '',
                dispatchedBy: d['dispatched_by'] ?? 'Sistema',
              );
            }).toList());
  }

  /// Mark alert as acknowledged by the guard
  Future<void> acknowledgeAlert(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'status': 'acknowledged',
      'acknowledged_at': DateTime.now().toIso8601String(),
    });
  }

  /// Escalate alert (request reinforcements) — writes back to Firestore
  /// so the platform can see the response
  Future<void> escalateAlert(String alertId) async {
    await _firestore.collection('alerts').doc(alertId).update({
      'status': 'escalated',
      'escalated_at': DateTime.now().toIso8601String(),
      'reinforcements_requested': true,
    });
  }

  /// Authenticate a guard by username and password.
  /// Returns the Guard object if credentials match, null otherwise.
  Future<Guard?> login(String username, String password) async {
    final snapshot = await _firestore
        .collection('guards')
        .where('username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    return Guard.fromFirestore(doc.id, doc.data());
  }

  /// Stream to listen for real-time updates to a guard's assigned location.
  Stream<Guard?> guardStream(String guardId) {
    return _firestore
        .collection('guards')
        .doc(guardId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Guard.fromFirestore(doc.id, doc.data()!);
    });
  }

  /// Update guard status (e.g., 'on_patrol', 'responding', etc.)
  Future<void> updateGuardStatus(String guardId, String status) async {
    await _firestore.collection('guards').doc(guardId).update({
      'status': status,
      'last_update': DateTime.now().toIso8601String(),
    });
  }

  String _buildTitle(Map<String, dynamic> d) {
    final frp = (d['frp'] as num?)?.toDouble() ?? 0;
    final region = d['region'] ?? 'Bolivia';
    if (frp > 50) return 'Foco de Alta Potencia — $region';
    if (frp > 10) return 'Foco de Media Potencia — $region';
    return 'Foco Detectado — $region';
  }

  String _buildDescription(Map<String, dynamic> d) {
    final frp = (d['frp'] as num?)?.toDouble() ?? 0;
    final conf = d['confidence'] ?? '—';
    final date = d['acq_date'] ?? '';
    final sensor = d['sensor'] ?? '';
    final by = d['dispatched_by'] ?? 'Operador';
    return 'Alerta despachada por $by. '
        'FRP: ${frp.toStringAsFixed(1)} MW | Confianza: $conf | '
        'Sensor: $sensor | Fecha detección: $date.';
  }
}
