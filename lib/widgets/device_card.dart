import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../services/device_service.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOn = device.isOn;
    final statusColor = _getStatusColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: isOn
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      device.typeColor.withValues(alpha: 0.15),
                      device.typeColor.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            border: Border.all(
              color: isOn ? device.typeColor.withValues(alpha: 0.3) : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Status indicator corner
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon and type
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: device.typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            device.icon,
                            color: device.typeColor,
                            size: 24,
                          ),
                        ),
                        const Spacer(),
                        if (device.isMock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'DEMO',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Device name
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // IP address
                    Text(
                      device.ipAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Power state and controls
                    Row(
                      children: [
                        // Power indicator
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isOn
                                  ? device.typeColor.withValues(alpha: 0.2)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isOn ? Icons.power_settings_new : Icons.power_settings_new_outlined,
                                  size: 18,
                                  color: isOn ? device.typeColor : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOn ? 'ON' : 'OFF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isOn ? device.typeColor : theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Toggle button
                        Material(
                          color: isOn ? device.typeColor : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: onToggle,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                transitionBuilder: (child, animation) {
                                  return RotationTransition(
                                    turns: animation,
                                    child: ScaleTransition(scale: animation, child: child),
                                  );
                                },
                                child: Icon(
                                  isOn ? Icons.toggle_on : Icons.toggle_off,
                                  key: ValueKey(isOn),
                                  color: isOn ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Additional info (brightness, speed, etc.)
                    if (isOn && (device.brightness != null || device.speed != null)) ...[
                      const SizedBox(height: 8),
                      _buildExtraInfo(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (device.status) {
      case DeviceStatus.online:
        return Colors.green;
      case DeviceStatus.offline:
        return Colors.red;
      case DeviceStatus.unknown:
        return Colors.orange;
    }
  }

  Widget _buildExtraInfo(BuildContext context) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];

    if (device.brightness != null) {
      widgets.add(_InfoChip(
        icon: Icons.brightness_6,
        label: '${device.brightness}%',
        color: Colors.amber,
      ));
    }

    if (device.temperature != null) {
      widgets.add(_InfoChip(
        icon: Icons.thermostat,
        label: '${device.temperature}K',
        color: Colors.orange,
      ));
    }

    if (device.speed != null) {
      widgets.add(_InfoChip(
        icon: Icons.air,
        label: 'Speed ${device.speed}',
        color: Colors.blue,
      ));
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: widgets,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}