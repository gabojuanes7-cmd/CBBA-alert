import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/alert.dart';
import '../models/drone.dart';
import '../models/sensor.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/drone_selector.dart';
import 'drone_camera_screen.dart';

class AlertDetailScreen extends StatefulWidget {
  final Alert alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen>
    with TickerProviderStateMixin {
  bool _isDroneDeployed = false;
  String _deployedDroneName = '';
  bool _reinforcementsCalled = false;
  late List<Sensor> _sensors;
  late AnimationController _fadeController;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _sensors = DispatcherService.getSensorsNear(widget.alert.lat, widget.alert.lon);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showDroneSelector() {
    final drones = DispatcherService.getAvailableDrones();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DroneSelector(
        targetLat: widget.alert.lat,
        targetLon: widget.alert.lon,
        drones: drones,
        onDeploy: (drone) {
          Navigator.pop(sheetContext); // Cerrar el selector

          setState(() {
            _isDroneDeployed = true;
            _deployedDroneName = drone.name;
          });
          
          DispatcherService.deployDrone(drone, widget.alert);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${drone.name} desplegado y añadido a la pestaña DRONES. ETA: ${drone.estimatedMinutesTo(widget.alert.lat, widget.alert.lon)} min',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.colorSuccess.withOpacity(0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          );
        },
      ),
    );
  }

  void _callReinforcements() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppTheme.colorCritical.withOpacity(0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.colorCritical, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Confirmar Escalamiento',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas escalar esta alerta como EMERGENCIA GRAVE y solicitar refuerzos de bomberos y guardabosques?\n\nEsto enviará una notificación urgente al centro de mando.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colorCritical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _reinforcementsCalled = true);
              
              // Actualiza Firebase
              await _firebaseService.escalateAlert(widget.alert.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text('¡Alerta escalada! Refuerzos en camino.',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    backgroundColor: AppTheme.colorCritical.withOpacity(0.9),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                );
              }
            },
            child: const Text('CONFIRMAR ESCALAMIENTO', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final isCritical = alert.level == 'critical';
    final accentColor = isCritical ? AppTheme.colorCritical : AppTheme.colorWarning;
    final center = LatLng(alert.lat, alert.lon);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: FadeTransition(
        opacity: _fadeController,
        child: CustomScrollView(
          slivers: [
            // ═══ MAP + APP BAR ═══
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: AppTheme.bgPanel,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.bgGlass,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Interactive Map
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),
                        MarkerLayer(
                          markers: [
                            // Fire marker with glow
                            Marker(
                              point: center,
                              width: 50,
                              height: 50,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Outer pulse
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accentColor.withOpacity(0.15),
                                    ),
                                  ),
                                  // Inner dot
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accentColor,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: accentColor.withOpacity(0.6), blurRadius: 12),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sensor markers
                            ..._sensors.map((s) => Marker(
                                  point: LatLng(s.lat, s.lon),
                                  width: 28,
                                  height: 28,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgSecondary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: s.status == 'alert'
                                            ? AppTheme.colorWarning.withOpacity(0.6)
                                            : AppTheme.colorSuccess.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(s.typeIcon, style: const TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
                    // Bottom gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 60,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, AppTheme.bgPrimary],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ═══ CONTENT ═══
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, color: accentColor, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            alert.zoneLabel,
                            style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      alert.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      alert.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Info Panel ──
                    _buildInfoPanel(alert),
                    const SizedBox(height: 20),

                    // ── Sensor Data Section ──
                    _buildSensorSection(),
                    const SizedBox(height: 24),

                    // ── Action Buttons ──
                    _buildDroneButton(accentColor),
                    const SizedBox(height: 12),
                    _buildReinforcementsButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(Alert alert) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _infoRow(Icons.my_location, 'Coordenadas', alert.coordsFormatted),
          _divider(),
          _infoRow(Icons.schedule, 'Detectado', alert.formattedDate),
          _divider(),
          _infoRow(Icons.satellite_alt, 'Fuente', alert.source),
          _divider(),
          _infoRow(Icons.tag, 'ID Alerta', alert.id),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 16),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: AppTheme.borderColor);
  }

  // ═══ SENSOR SECTION ═══
  Widget _buildSensorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sensors, color: AppTheme.brandPrimary, size: 16),
            const SizedBox(width: 8),
            const Text(
              'SENSORES CERCANOS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.colorSuccessBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.colorSuccess.withOpacity(0.2)),
              ),
              child: Text(
                '${_sensors.length} ACTIVOS',
                style: const TextStyle(color: AppTheme.colorSuccess, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
          ),
          itemCount: _sensors.length,
          itemBuilder: (context, index) {
            final sensor = _sensors[index];
            final isAlert = sensor.status == 'alert';
            final statusColor = isAlert ? AppTheme.colorWarning : AppTheme.colorSuccess;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: statusColor.withOpacity(isAlert ? 0.2 : 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(sensor.typeIcon, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          boxShadow: [BoxShadow(color: statusColor.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    sensor.formattedValue,
                    style: TextStyle(
                      color: isAlert ? AppTheme.colorWarning : AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    sensor.typeLabel,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══ DRONE BUTTON ═══
  Widget _buildDroneButton(Color accentColor) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: _isDroneDeployed
          ? Container(
              decoration: BoxDecoration(
                color: AppTheme.colorSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.colorSuccess.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flight_land, color: AppTheme.colorSuccess, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'DRON DESPLEGADO: $_deployedDroneName',
                    style: const TextStyle(
                      color: AppTheme.colorSuccess,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showDroneSelector,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3A5C), Color(0xFF0C1120)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.colorInfo.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flight_takeoff, color: AppTheme.colorInfo, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'DESPLEGAR DRON',
                        style: TextStyle(
                          color: AppTheme.colorInfo,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ═══ REINFORCEMENTS BUTTON ═══
  Widget _buildReinforcementsButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: _reinforcementsCalled
          ? Container(
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.textMuted.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppTheme.textMuted, size: 18),
                  SizedBox(width: 10),
                  Text(
                    'REFUERZOS NOTIFICADOS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            )
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _callReinforcements,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B0715), Color(0xFF0C1120)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.colorCritical.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign, color: AppTheme.colorCritical, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'SOLICITAR REFUERZOS',
                        style: TextStyle(
                          color: AppTheme.colorCritical,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
