import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import '../services/device_service.dart';
import '../services/mock_shelly_client.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  DeviceType _selectedType = DeviceType.light;
  bool _isTesting = false;
  String? _testResult;

  // Quick-add suggestions for mock devices
  final List<_QuickAdd> _quickAdds = [
    _QuickAdd('Living Room Light', '192.168.1.42', DeviceType.light),
    _QuickAdd('Bedroom Fan', '192.168.1.43', DeviceType.fan),
    _QuickAdd('Bathroom Switch', '192.168.1.44', DeviceType.switch),
    _QuickAdd('Garage Relay', '192.168.1.45', DeviceType.relay),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final mockClient = MockShellyClient();
      final status = await mockClient.getStatus(_ipController.text);

      if (status != null) {
        setState(() {
          _testResult = '✓ Connected! Found "${status.name}" (${status.type.displayType})';
        });
      } else {
        setState(() {
          _testResult = '✗ Device not found at this IP';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '✗ Error: $e';
      });
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    final service = context.read<DeviceService>();
    try {
      await service.addDevice(
        name: _nameController.text.trim(),
        type: _selectedType,
        ipAddress: _ipController.text.trim(),
        port: int.tryParse(_portController.text) ?? 80,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add device: $e')),
        );
      }
    }
  }

  void _useQuickAdd(_QuickAdd quickAdd) {
    _nameController.text = quickAdd.name;
    _ipController.text = quickAdd.ip;
    _selectedType = quickAdd.type;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMock = context.watch<DeviceService>().mockMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        actions: [
          if (isMock)
            Chip(
              label: const Text('Mock Mode'),
              avatar: const Icon(Icons.science, size: 16),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick add section
              Text('Quick Add (Mock)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickAdds.map((q) => ActionChip(
                  label: Text(q.name),
                  icon: Icon(_iconForType(q.type), size: 16),
                  onPressed: () => _useQuickAdd(q),
                )).toList(),
              ),
              const SizedBox(height: 24),

              // Device type selector
              Text('Device Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<DeviceType>(
                segments: DeviceType.values.map((type) => ButtonSegment(
                  value: type,
                  label: Text(type.displayType),
                  icon: Icon(_iconForType(type)),
                )).toList(),
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  setState(() => _selectedType = selection.first);
                },
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'e.g., Living Room Light',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // IP address field
              TextFormField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.xxx',
                  prefixIcon: Icon(Icons.router),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an IP address';
                  }
                  if (!_isValidIP(value.trim())) {
                    return 'Enter a valid IP address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Port field
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final port = int.tryParse(value ?? '');
                  if (port == null || port < 1 || port > 65535) {
                    return 'Valid port (1-65535)';
                  }
                  return null,
                },
              ),
              const SizedBox(height: 24),

              // Test connection button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isTesting ? null : _testConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_find),
                  label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                ),
              ),
              const SizedBox(height: 8),

              // Test result
              if (_testResult != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testResult!.startsWith('✓')
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _testResult!.startsWith('✓')
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testResult!.startsWith('✓') ? Colors.green : Colors.red,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Add device button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _addDevice,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Device'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              if (!isMock) ...[
                const SizedBox(height: 16),
                Text(
                  'Note: Mock mode is disabled. Add a real Shelly device on your network, or enable Mock Mode in Settings to test with simulated devices.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  IconData _iconForType(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return Icons.lightbulb;
      case DeviceType.fan:
        return Icons.air;
      case DeviceType.switch:
        return Icons.toggle_on;
      case DeviceType.relay:
        return Icons.electrical_services;
    }
  }
}

class _QuickAdd {
  final String name;
  final String ip;
  final DeviceType type;

  _QuickAdd(this.name, this.ip, this.type);
}