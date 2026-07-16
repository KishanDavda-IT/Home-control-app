import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../widgets/device_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshDevices());
  }

  Future<void> _refreshDevices() async {
    final service = context.read<DeviceService>();
    await service.discoverDevices();
  }

  Future<void> _onDiscover() async {
    setState(() => _isDiscovering = true);
    try {
      await _refreshDevices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discovery complete')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDiscovering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DeviceService>();
    final devices = service.devices;

    final onlineDevices = devices.where((d) => d.status == DeviceStatus.online).toList();
    final offlineDevices = devices.where((d) => d.status == DeviceStatus.offline).toList();
    final unknownDevices = devices.where((d) => d.status == DeviceStatus.unknown).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LightFan Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isDiscovering ? null : _onDiscover,
            tooltip: 'Discover devices',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDevices,
        child: devices.isEmpty
            ? const _EmptyState()
            : CustomScrollView(
                slivers: [
                  if (onlineDevices.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Online',
                        count: onlineDevices.length,
                        color: Colors.green,
                      ),
                    ),
                  if (onlineDevices.isNotEmpty)
                    _DeviceGrid(devices: onlineDevices),

                  if (unknownDevices.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Unknown',
                        count: unknownDevices.length,
                        color: Colors.orange,
                      ),
                    ),
                  if (unknownDevices.isNotEmpty)
                    _DeviceGrid(devices: unknownDevices),

                  if (offlineDevices.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Offline',
                        count: offlineDevices.length,
                        color: Colors.red,
                      ),
                    ),
                  if (offlineDevices.isNotEmpty)
                    _DeviceGrid(devices: offlineDevices),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-device'),
        icon: const Icon(Icons.add),
        label: const Text('Add Device'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first Shelly device',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-device'),
              icon: const Icon(Icons.add),
              label: const Text('Add Device'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceGrid extends StatelessWidget {
  final List<Device> devices;

  const _DeviceGrid({required this.devices});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final device = devices[index];
            return DeviceCard(
              device: device,
              onTap: () => Navigator.pushNamed(
                context,
                '/device-detail',
                arguments: device,
              ),
              onToggle: () => context.read<DeviceService>().toggleDevice(device.id),
            );
          },
          childCount: devices.length,
        ),
      ),
    );
  }
}