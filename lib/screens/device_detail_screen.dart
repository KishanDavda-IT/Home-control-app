import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../services/device_service.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late Device _device;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
  }

  void _updateDevice(Device updated) {
    setState(() => _device = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = context.watch<DeviceService>();

    // Find latest device state
    final latestDevice = service.devices.firstWhere(
      (d) => d.id == _device.id,
      orElse: () => _device,
    );
    _device = latestDevice;

    return Scaffold(
      appBar: AppBar(
        title: Text(_device.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => service.refreshDevice(_device.id),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.pushNamed(context, '/add-device', arguments: _device);
                  break;
                case 'delete':
                  _confirmDelete();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main device card
          _MainDeviceCard(device: _device),

          const SizedBox(height: 24),

          // Controls based on device type
          _buildControls(),

          const SizedBox(height: 24),

          // Device info
          _DeviceInfoCard(device: _device),

          const SizedBox(height: 24),

          // Power/Energy info (if available)
          if (_device.type == DeviceType.light || _device.type == DeviceType.fan)
            _EnergyInfoCard(device: _device),
        ],
      ),
    );
  }

  Widget _buildControls() {
    switch (_device.type) {
      case DeviceType.light:
        return _LightControls(device: _device);
      case DeviceType.fan:
        return _FanControls(device: _device);
      case DeviceType.switch:
      case DeviceType.relay:
        return _SwitchControls(device: _device);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device?'),
        content: Text('Remove "${_device.name}" from your devices?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<DeviceService>().removeDevice(_device.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MainDeviceCard extends StatelessWidget {
  final Device device;

  const _MainDeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOn = device.isOn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Icon with status glow
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOn
                    ? device.typeColor.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest,
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: device.typeColor.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                device.icon,
                size: 50,
                color: isOn ? device.typeColor : theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            // Status
            Text(
              isOn ? 'ON' : 'OFF',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isOn ? device.typeColor : theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 8),

            // Device name
            Text(
              device.name,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // IP and type
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(device.displayType),
                  avatar: Icon(device.icon, size: 16),
                  backgroundColor: device.typeColor.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 8),
                Text(
                  device.ipAddress,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Large toggle button
            FilledButton.icon(
              onPressed: () => context.read<DeviceService>().toggleDevice(device.id),
              icon: Icon(isOn ? Icons.toggle_on : Icons.toggle_off, size: 28),
              label: Text(
                isOn ? 'Turn Off' : 'Turn On',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isOn ? device.typeColor : theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LightControls extends StatelessWidget {
  final Device device;

  const _LightControls({required this.device});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeviceService>();
    final brightness = device.brightness ?? 100;
    final temperature = device.temperature ?? 4000;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Light Controls', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // Brightness
            Text('Brightness: $brightness%', style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: brightness.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$brightness%',
              onChanged: device.isOn
                  ? (v) => service.setBrightness(device.id, v.round())
                  : null,
            ),

            const SizedBox(height: 16),

            // Color temperature
            Text('Color Temp: ${temperature}K', style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: temperature.toDouble(),
              min: 2700,
              max: 6500,
              divisions: 19,
              label: '${temperature}K',
              onChanged: device.isOn
                  ? (v) => service.setTemperature(device.id, v.round())
                  : null,
            ),

            const SizedBox(height: 8),

            // Preset temperatures
            Wrap(
              spacing: 8,
              children: [
                _TempPreset(label: 'Warm', temp: 2700, current: temperature, onTap: () => device.isOn ? service.setTemperature(device.id, 2700) : null),
                _TempPreset(label: 'Neutral', temp: 4000, current: temperature, onTap: () => device.isOn ? service.setTemperature(device.id, 4000) : null),
                _TempPreset(label: 'Cool', temp: 6500, current: temperature, onTap: () => device.isOn ? service.setTemperature(device.id, 6500) : null),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TempPreset extends StatelessWidget {
  final String label;
  final int temp;
  final int current;
  final VoidCallback? onTap;

  const _TempPreset({required this.label, required this.temp, required this.current, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == temp;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap?.call(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _FanControls extends StatelessWidget {
  final Device device;

  const _FanControls({required this.device});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeviceService>();
    final speed = device.speed ?? 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fan Controls', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // Speed selector
            Text('Speed: $speed', style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: speed.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: speed == 0 ? 'Off' : 'Speed $speed',
              onChanged: (v) => service.setFanSpeed(device.id, v.round()),
            ),

            const SizedBox(height: 16),

            // Speed presets
            Wrap(
              spacing: 8,
              children: [
                _SpeedButton(label: 'Off', speed: 0, current: speed, onTap: () => service.setFanSpeed(device.id, 0)),
                _SpeedButton(label: 'Low', speed: 1, current: speed, onTap: () => service.setFanSpeed(device.id, 1)),
                _SpeedButton(label: 'Med', speed: 2, current: speed, onTap: () => service.setFanSpeed(device.id, 2)),
                _SpeedButton(label: 'High', speed: 3, current: speed, onTap: () => service.setFanSpeed(device.id, 3)),
                _SpeedButton(label: 'Max', speed: 4, current: speed, onTap: () => service.setFanSpeed(device.id, 4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final int speed;
  final int current;
  final VoidCallback onTap;

  const _SpeedButton({required this.label, required this.speed, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == speed;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }
}

class _SwitchControls extends StatelessWidget {
  final Device device;

  const _SwitchControls({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: device.isOn ? null : () => context.read<DeviceService>().turnOn(device.id),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Turn On'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !device.isOn ? null : () => context.read<DeviceService>().turnOff(device.id),
                    icon: const Icon(Icons.power_settings_new_outlined),
                    label: const Text('Turn Off'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceInfoCard extends StatelessWidget {
  final Device device;

  const _DeviceInfoCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _InfoRow(label: 'IP Address', value: device.ipAddress),
            _InfoRow(label: 'Port', value: device.port.toString()),
            _InfoRow(label: 'Type', value: device.displayType),
            _InfoRow(
              label: 'Status',
              value: device.status.name.capitalize(),
              valueStyle: TextStyle(
                color: device.status == DeviceStatus.online
                    ? Colors.green
                    : device.status == DeviceStatus.offline
                        ? Colors.red
                        : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            _InfoRow(label: 'Last Seen', value: _formatLastSeen(device.lastSeen)),
            if (device.macAddress != null)
              _InfoRow(label: 'MAC Address', value: device.macAddress!),
            if (device.isMock)
              _InfoRow(
                label: 'Mode',
                value: 'Mock (Simulated)',
                valueStyle: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }

  String _formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ).merge(valueStyle),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyInfoCard extends StatelessWidget {
  final Device device;

  const _EnergyInfoCard({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Power Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // These would come from real device; showing placeholders for mock
            if (device.isMock) ...[
              _InfoRow(label: 'Power', value: '12.5 W'),
              _InfoRow(label: 'Voltage', value: '230 V'),
              _InfoRow(label: 'Current', value: '0.054 A'),
              _InfoRow(label: 'Energy Today', value: '1.2 kWh'),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Connect a real Shelly device to see power data'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}