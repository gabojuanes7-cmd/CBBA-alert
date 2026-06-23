import 'package:flutter/material.dart';
import '../models/drone.dart';
import '../theme/app_theme.dart';

class DroneSelector extends StatelessWidget {
  final double targetLat;
  final double targetLon;
  final List<Drone> drones;
  final Function(Drone) onDeploy;

  const DroneSelector({
    super.key,
    required this.targetLat,
    required this.targetLon,
    required this.drones,
    required this.onDeploy,
  });

  @override
  Widget build(BuildContext context) {
    // Sort by distance
    final sortedDrones = List<Drone>.from(drones)
      ..sort((a, b) => a.distanceTo(targetLat, targetLon)
          .compareTo(b.distanceTo(targetLat, targetLon)));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
        border: Border(
          top: BorderSide(color: AppTheme.borderGlow, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMuted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3A5C), Color(0xFF0C1120)],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.colorInfo.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.flight_takeoff, color: AppTheme.colorInfo, size: 18),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drones Disponibles',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Ordenados por distancia al objetivo',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Drone list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: sortedDrones.length,
              itemBuilder: (context, index) {
                final drone = sortedDrones[index];
                final isAvailable = drone.status == 'available';
                final distance = drone.distanceTo(targetLat, targetLon).toStringAsFixed(1);
                final eta = drone.estimatedMinutesTo(targetLat, targetLon);
                final isClosest = index == 0 && isAvailable;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isClosest
                          ? AppTheme.colorInfo.withOpacity(0.3)
                          : isAvailable
                              ? AppTheme.borderColor
                              : AppTheme.colorCritical.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Icon with status indicator
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isAvailable
                                    ? AppTheme.colorInfo.withOpacity(0.08)
                                    : AppTheme.textMuted.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                              ),
                              child: Icon(
                                Icons.airplanemode_active,
                                color: isAvailable ? AppTheme.colorInfo : AppTheme.textMuted,
                                size: 22,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAvailable ? AppTheme.colorSuccess : AppTheme.colorCritical,
                                  border: Border.all(color: AppTheme.bgSecondary, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    drone.name,
                                    style: TextStyle(
                                      color: isAvailable ? AppTheme.textPrimary : AppTheme.textMuted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (isClosest) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandPrimary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppTheme.brandPrimary.withOpacity(0.3)),
                                      ),
                                      child: const Text(
                                        'MÁS CERCANO',
                                        style: TextStyle(
                                          color: AppTheme.brandPrimary,
                                          fontSize: 7,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _droneMetaChip(Icons.battery_charging_full,
                                      '${drone.batteryLevel.toInt()}%',
                                      drone.batteryLevel > 30 ? AppTheme.colorSuccess : AppTheme.colorCritical),
                                  const SizedBox(width: 8),
                                  _droneMetaChip(Icons.straighten, '$distance km', AppTheme.textSecondary),
                                  const SizedBox(width: 8),
                                  _droneMetaChip(Icons.timer, '~$eta min', AppTheme.textSecondary),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${drone.type} · ${drone.cameraType}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Action button
                        const SizedBox(width: 8),
                        isAvailable
                            ? Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    onDeploy(drone);
                                  },
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      gradient: isClosest
                                          ? AppTheme.brandGradient
                                          : const LinearGradient(
                                              colors: [Color(0xFF1A3A5C), Color(0xFF0C1120)]),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                      border: isClosest
                                          ? null
                                          : Border.all(color: AppTheme.colorInfo.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      'ENVIAR',
                                      style: TextStyle(
                                        color: isClosest ? Colors.white : AppTheme.colorInfo,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.colorCritical.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                child: const Text(
                                  'MANT.',
                                  style: TextStyle(
                                    color: AppTheme.colorCritical,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _droneMetaChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
