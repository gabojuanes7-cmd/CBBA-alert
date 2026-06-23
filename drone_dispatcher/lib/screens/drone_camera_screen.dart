import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/app_theme.dart';

class DroneCameraScreen extends StatefulWidget {
  final String droneName;

  const DroneCameraScreen({super.key, required this.droneName});

  @override
  State<DroneCameraScreen> createState() => _DroneCameraScreenState();
}

class _DroneCameraScreenState extends State<DroneCameraScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isConnected = false;
  late AnimationController _flashController;

  @override
  void initState() {
    super.initState();
    
    // Map drones to specific videos
    String videoAsset = 'assets/videos/dron1.webm';
    if (widget.droneName.contains('Beta')) {
      videoAsset = 'assets/videos/dron2.webm';
    } else if (widget.droneName.contains('Gamma')) {
      videoAsset = 'assets/videos/dron3.webm';
    }
    
    _controller = VideoPlayerController.asset(videoAsset)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {}); // Trigger rebuild when initialized
        }
        _controller.setLooping(true);
        _controller.setVolume(0.0); // Mute for HUD effect
      }).catchError((error) {
        print("Error initializing video: $error");
      });

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
      
    _simulateConnection();
  }

  Future<void> _simulateConnection() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isConnected = true;
      });
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _flashController.dispose();
    super.dispose();
  }

  void _takePhoto() async {
    // Shutter flash effect
    await _flashController.forward();
    _flashController.reverse();

    if (!mounted) return;

    final photoIndex = Random().nextInt(2) + 1; // 1 o 2
    final photoAsset = 'assets/images/reporte $photoIndex.jpg';

    // Show report dialog
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
                  const Text('INFORME RÁPIDO GENERADO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 Ubicación guardada: -17.382, -66.155', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('🕒 Marca de tiempo: Automática', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('📊 Estimación área afectada: ~1.2 hectáreas', style: TextStyle(color: Colors.white70, fontSize: 12)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Video Layer
          Positioned.fill(
            child: _isConnected && _controller.value.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.brandPrimary),
                        SizedBox(height: 16),
                        Text(
                          'ESTABLECIENDO ENLACE...',
                          style: TextStyle(color: AppTheme.brandPrimary, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
          ),

          // 2. Drone HUD Overlay
          if (_isConnected) ...[
            // Crosshair
            Center(
              child: CustomPaint(
                size: const Size(100, 100),
                painter: _CrosshairPainter(),
              ),
            ),
            
            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'UAV: ${widget.droneName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'REC',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 16),
                        _buildHudBadge(Icons.battery_charging_full, '87%'),
                        const SizedBox(width: 8),
                        _buildHudBadge(Icons.wifi, 'HD'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Telemetry - Bottom
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTelemetryText('ALT: 120m'),
                      _buildTelemetryText('SPD: 45 km/h'),
                      _buildTelemetryText('MODE: IR/THERMAL'),
                    ],
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Text(
                        'PITCH\n-5°',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.greenAccent.withOpacity(0.8), fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTelemetryText('LAT: -17.382'),
                      _buildTelemetryText('LON: -66.155'),
                      _buildTelemetryText('DIST: 2.4km'),
                    ],
                  ),
                ],
              ),
            ),

            // Camera Controls - Right side
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 40,
              child: GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.black, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 3. Flash overlay (animates on photo taken)
          AnimatedBuilder(
            animation: _flashController,
            builder: (context, child) {
              return IgnorePointer(
                child: Container(
                  color: Colors.white.withOpacity(_flashController.value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHudBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildTelemetryText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final length = size.width / 4;

    // Center dot
    canvas.drawCircle(center, 2, Paint()..color = Colors.red);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - length, center.dy), Offset(center.dx - 10, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 10, center.dy), Offset(center.dx + length, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - length), Offset(center.dx, center.dy - 10), paint);
    canvas.drawLine(Offset(center.dx, center.dy + 10), Offset(center.dx, center.dy + length), paint);

    // Corners
    final cornerLength = length / 2;
    // Top left
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), paint);
    // Top right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);
    // Bottom left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);
    // Bottom right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
