import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mock mode toggle
          _SettingsSection(
            title: 'Development',
            children: [
              Consumer<DeviceService>(
                builder: (context, service, _) => SwitchListTile(
                  title: const Text('Mock Mode'),
                  subtitle: const Text('Use simulated devices for testing'),
                  value: service.mockMode,
                  onChanged: (v) => service.setMockMode(v),
                  secondary: const Icon(Icons.science),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Rediscover Devices'),
                subtitle: const Text('Scan network for Shelly devices'),
                onTap: () {
                  context.read<DeviceService>().discoverDevices();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Discovery started...')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add Demo Devices'),
                subtitle: const Text('Populate with sample light, fan, and switch'),
                onTap: () => _addDemoDevices(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App settings
          _SettingsSection(
            title: 'App Settings',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: const Text('System default (Light/Dark)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context),
              ),
              SwitchListTile(
                title: const Text('Auto Refresh'),
                subtitle: const Text('Periodically update device status'),
                value: true,
                onChanged: (v) {},
                secondary: const Icon(Icons.autorenew),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Source Code'),
                subtitle: const Text('GitHub repository'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Report Issue'),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Reset button
          Consumer<DeviceService>(
            builder: (context, service, _) => FilledButton.icon(
              onPressed: service.devices.isEmpty
                  ? null
                  : () => _confirmReset(context, service),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Remove All Devices'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addDemoDevices(BuildContext context) {
    context.read<DeviceService>().addDemoDevices();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo devices added')),
    );
  }

  void _confirmReset(BuildContext context, DeviceService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove All Devices?'),
        content: const Text('This will delete all saved devices. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              service.clearAllDevices();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All devices removed')),
              );
            },
            child: const Text('Remove All'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: const Text('Currently follows system theme (Light/Dark). Manual theme selection coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}