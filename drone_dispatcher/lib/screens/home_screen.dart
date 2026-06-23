import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../models/alert.dart';
import '../models/drone.dart';
import '../models/guard.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'alert_detail_screen.dart';
import 'drone_camera_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final Guard? guard;
  const HomeScreen({super.key, this.guard});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  final FirebaseService _firebaseService = FirebaseService();

  // Fallback demo data when Firebase has no data yet
  List<Alert> _demoUrgent = [];
  List<Alert> _demoReview = [];
  final bool _useDemo = true;
  String _lastUrgentAlertId = '';
  StreamSubscription? _urgentSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Prepare demo data for when Firebase is empty
    final allDemo = DispatcherService.getDispatchedAlerts();
    _demoUrgent = allDemo.where((a) => a.level == 'critical').toList();
    _demoReview = allDemo.where((a) => a.level == 'warning').toList();

    _listenForAlarms();
  }

  void _listenForAlarms() {
    _urgentSubscription = _firebaseService.getUrgentAlerts().listen((alerts) {
      if (alerts.isNotEmpty) {
        final newestAlert = alerts.first;
        // Si hay una alerta nueva que no hemos visto
        if (_lastUrgentAlertId.isNotEmpty && _lastUrgentAlertId != newestAlert.id) {
          _triggerAlarm(newestAlert);
        }
        _lastUrgentAlertId = newestAlert.id;
      }
    });
  }

  void _triggerAlarm(Alert alert) {
    FlutterRingtonePlayer().playAlarm();
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.colorCriticalBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: const BorderSide(color: AppTheme.colorCritical, width: 2),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.colorCritical, size: 32),
              SizedBox(width: 10),
              Text(
                '¡ALERTA DE EMERGENCIA!',
                style: TextStyle(color: AppTheme.colorCritical, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: Text(
            'Nueva alerta despachada: ${alert.title}\n\nPor favor revisa los detalles inmediatamente.',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colorCritical,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                FlutterRingtonePlayer().stop();
                Navigator.pop(ctx);
                _tabController.animateTo(0); // Ve a la pestaña urgente
              },
              child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _urgentSubscription?.cancel();
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ═══ PREMIUM APP BAR ═══
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.bgPanel,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0C1120), Color(0xFF06080F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    // Gradient accent line at bottom
                    Positioned(
                      bottom: 48,
                      left: 0,
                      right: 0,
                      height: 1.5,
                      child: Container(
                        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.brandGradient,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                    boxShadow: AppTheme.glowBrand,
                                  ),
                                  child: const Icon(Icons.local_fire_department, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            AppTheme.brandGradient.createShader(bounds),
                                        child: const Text(
                                          'AlertaCBBA',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        widget.guard != null
                                            ? '${widget.guard!.name} · ${widget.guard!.role}'
                                            : 'CENTRO DE DESPACHO MÓVIL',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      if (widget.guard != null)
                                        Text(
                                          '📍 ${widget.guard!.lat.toStringAsFixed(4)}, ${widget.guard!.lon.toStringAsFixed(4)}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: const Color(0xFF4ECDC4).withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Status indicator
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.colorSuccessBg,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.colorSuccess.withOpacity(
                                              0.2 + _pulseController.value * 0.15),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppTheme.colorSuccess,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.colorSuccess.withOpacity(0.5),
                                                  blurRadius: 4 + _pulseController.value * 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'EN LÍNEA',
                                            style: TextStyle(
                                              color: AppTheme.colorSuccess,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Mini stats
                            Row(
                              children: [
                                _buildMiniStat(Icons.notifications_active, '—', 'Alertas', AppTheme.colorCritical),
                                const SizedBox(width: 10),
                                _buildMiniStat(Icons.flight_takeoff,
                                    '${DispatcherService.getAvailableDrones().where((d) => d.status == "available").length}',
                                    'Drones', AppTheme.colorInfo),
                                const SizedBox(width: 10),
                                _buildMiniStat(Icons.sensors, '4', 'Sensores', AppTheme.colorSuccess),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: AppTheme.bgSecondary,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.brandPrimary,
                  indicatorWeight: 2.5,
                  labelColor: AppTheme.brandPrimary,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.warning_amber_rounded, size: 16),
                      text: 'URGENTES',
                    ),
                    Tab(
                      icon: Icon(Icons.assignment_outlined, size: 16),
                      text: 'REVISIÓN',
                    ),
                    Tab(
                      icon: Icon(Icons.flight_takeoff, size: 16),
                      text: 'DRONES',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ═══ TAB 1: URGENTES ═══
            _buildAlertStream(
              stream: _firebaseService.getUrgentAlerts(),
              fallbackAlerts: _demoUrgent,
              emptyIcon: Icons.shield,
              emptyText: 'Sin alertas urgentes\nTodas las zonas están en calma.',
              isUrgent: true,
            ),
            // ═══ TAB 2: REVISIÓN ═══
            _buildAlertStream(
              stream: _firebaseService.getReviewAlerts(),
              fallbackAlerts: _demoReview,
              emptyIcon: Icons.check_circle_outline,
              emptyText: 'Sin alertas de revisión\nNada pendiente para la ronda.',
              isUrgent: false,
            ),
            // ═══ TAB 3: DRONES ═══
            _buildDronesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildDronesTab() {
    return ValueListenableBuilder<List<DeployedDrone>>(
      valueListenable: DispatcherService.deployedDronesNotifier,
      builder: (context, drones, child) {
        if (drones.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.flight_land, color: AppTheme.textMuted, size: 48),
                SizedBox(height: 16),
                Text(
                  'No hay drones desplegados\nDespliega uno desde una alerta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: drones.length,
          itemBuilder: (context, index) {
            final deployed = drones[index];
            return Card(
              color: AppTheme.bgCard,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                side: BorderSide(color: AppTheme.colorInfo.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flight, color: AppTheme.colorInfo, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          deployed.drone.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.colorInfo.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'EN VUELO',
                            style: TextStyle(color: AppTheme.colorInfo, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Destino: ${deployed.targetAlert.title}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ubicación: ${deployed.targetAlert.coordsFormatted}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.colorInfo.withOpacity(0.2),
                              foregroundColor: AppTheme.colorInfo,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.videocam, size: 18),
                            label: const Text('VER CÁMARA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DroneCameraScreen(droneName: deployed.drone.name),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.colorSuccess.withOpacity(0.2),
                              foregroundColor: AppTheme.colorSuccess,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: const Text('CAPTURAR FOTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              // We just open the camera screen which automatically starts taking the photo, or we can just open the camera.
                              // Since the photo logic is inside DroneCameraScreen, let's just open the camera screen and tell them to click the button.
                              // Wait, the prompt says "salga las opciones de mostrar camara o sacar foto y ahi salgan las de aca"
                              // Let's just navigate to the camera screen in both, but maybe we can add a flag to auto-take photo?
                              // To keep it simple, both buttons can just go to the camera, or I can replicate the "Take Photo" dialog here.
                              // Replicating the dialog here is better for direct action. Let's do that!
                              _takePhoto(context, deployed);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _takePhoto(BuildContext context, DeployedDrone deployed) {
    final photoIndex = Random().nextInt(2) + 1; // 1 o 2
    final photoAsset = 'assets/images/reporte $photoIndex.jpg';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.document_scanner, color: AppTheme.brandPrimary),
                  const SizedBox(width: 8),
                  const Text('INFORME RÁPIDO DEL DRON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.asset(photoAsset, fit: BoxFit.cover, height: 200, width: double.infinity),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚁 Dron: ${deployed.drone.name}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('📍 Ubicación guardada: ${deployed.targetAlert.coordsFormatted}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text('🕒 Marca de tiempo: Automática', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.colorSuccess,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('GUARDAR EN BITÁCORA Y ENVIAR', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe enviado exitosamente a la plataforma.'),
                      backgroundColor: AppTheme.colorSuccess,
                    )
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertStream({
    required Stream<List<Alert>> stream,
    required List<Alert> fallbackAlerts,
    required IconData emptyIcon,
    required String emptyText,
    required bool isUrgent,
  }) {
    return StreamBuilder<List<Alert>>(
      stream: stream,
      builder: (context, snapshot) {
        List<Alert> alerts;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          alerts = snapshot.data!;
        } else if (snapshot.hasError || !snapshot.hasData) {
          // Use demo data as fallback
          alerts = fallbackAlerts;
        } else {
          alerts = fallbackAlerts;
        }

        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(emptyIcon, color: AppTheme.textMuted, size: 48),
                const SizedBox(height: 16),
                Text(
                  emptyText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _AlertCard(
              alert: alert,
              isUrgent: isUrgent,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => AlertDetailScreen(alert: alert),
                    transitionsBuilder: (_, anim, __, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// ALERT CARD
// ═══════════════════════════════════════════
class _AlertCard extends StatelessWidget {
  final Alert alert;
  final bool isUrgent;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.isUrgent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = isUrgent ? AppTheme.colorCritical : AppTheme.colorWarning;
    final bgGradient = isUrgent
        ? const LinearGradient(colors: [Color(0x0FFF3D3D), Color(0xB312192D)], begin: Alignment.topLeft, end: Alignment.bottomRight)
        : const LinearGradient(colors: [Color(0x0AFF8C00), Color(0xB312192D)], begin: Alignment.topLeft, end: Alignment.bottomRight);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              gradient: bgGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: accentColor.withOpacity(0.15)),
            ),
            child: Stack(
              children: [
                // Left accent bar
                Positioned(
                  left: 0, top: 0, bottom: 0, width: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppTheme.radiusMd),
                        bottomLeft: Radius.circular(AppTheme.radiusMd),
                      ),
                      boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 10)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accentColor.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isUrgent ? Icons.warning_amber_rounded : Icons.assignment, color: accentColor, size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  isUrgent ? 'URGENTE' : 'REVISIÓN',
                                  style: TextStyle(color: accentColor, fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                          if (alert.frp > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.brandPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${alert.frp.toStringAsFixed(1)} MW',
                                style: const TextStyle(color: AppTheme.brandPrimary, fontSize: 8, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(alert.timeAgo, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        alert.title,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.satellite_alt, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(alert.source, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(width: 16),
                          Icon(Icons.my_location, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(alert.coordsFormatted, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                          const Spacer(),
                          Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                        ],
                      ),
                    ],
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
