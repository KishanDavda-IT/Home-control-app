import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import 'shelly_client.dart';
import 'mock_shelly_client.dart';
import 'discovery_service.dart';

class DeviceService {
  static const String _devicesKey = 'saved_devices';
  static const String _mockModeKey = 'mock_mode';
  static const String _lastScanKey = 'last_scan';

  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

  MockShellyClient? _mockClient;
  final Map<String, ShellyClient> _realClients = {};
  final DiscoveryService _discoveryService = DiscoveryService();

  bool _mockMode = false;
  List<Device> _devices = [];
  StreamController<List<Device>>? _devicesController;

  DeviceService(this._prefs) {
    _loadSettings();
    _loadDevices();
  }

  // Initialize async parts
  Future<void> initialize() async {
    _mockClient = MockShellyClient();
    _devicesController = StreamController<List<Device>>.broadcast();
    await _startPeriodicUpdates();
  }

  // Public access to mock client for testing
  MockShellyClient? get mockClient => _mockClient;

  // Stream of device list for UI
  Stream<List<Device>> get devicesStream {
    _devicesController ??= StreamController<List<Device>>.broadcast();
    return _devicesController!.stream;
  }

  List<Device> get devices => List.unmodifiable(_devices);

  bool get mockMode => _mockMode;

  // Toggle mock mode
  Future<void> setMockMode(bool enabled) async {
    _mockMode = enabled;
    await _prefs.setBool(_mockModeKey, enabled);
    await _refreshAllDevices();
  }

  // Load settings from prefs
  void _loadSettings() {
    _mockMode = _prefs.getBool(_mockModeKey) ?? true; // Default to mock for testing
  }

  // Load devices from prefs
  void _loadDevices() {
    final jsonString = _prefs.getString(_devicesKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _devices = jsonList.map((j) => Device.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        _devices = [];
      }
    }
  }

  // Save devices to prefs
  Future<void> _saveDevices() async {
    final jsonString = jsonEncode(_devices.map((d) => d.toJson()).toList());
    await _prefs.setString(_devicesKey, jsonString);
  }

  // Notify listeners
  void _notify() {
    _devicesController?.add(List.unmodifiable(_devices));
  }

  // Add a new device
  Future<Device> addDevice({
    required String name,
    required DeviceType type,
    required String ipAddress,
    int port = 80,
    String? macAddress,
  }) async {
    final device = Device(
      id: _uuid.v4(),
      name: name,
      type: type,
      ipAddress: ipAddress,
      port: port,
      macAddress: macAddress,
      status: DeviceStatus.unknown,
    );

    _devices.add(device);
    await _saveDevices();
    await _refreshDevice(device);
    _notify();
    return device;
  }

  // Update device
  Future<void> updateDevice(Device device) async {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index >= 0) {
      _devices[index] = device;
      await _saveDevices();
      _notify();
    }
  }

  // Remove device
  Future<void> removeDevice(String deviceId) async {
    _devices.removeWhere((d) => d.id == deviceId);
    await _saveDevices();
    _notify();
  }

  // Clear all devices
  Future<void> clearAllDevices() async {
    _devices.clear();
    await _saveDevices();
    _notify();
  }

  // Add demo devices
  Future<void> addDemoDevices() async {
    await addDevice(
      name: 'Living Room Light',
      type: DeviceType.light,
      ipAddress: '192.168.1.42',
    );
    await addDevice(
      name: 'Bedroom Fan',
      type: DeviceType.fan,
      ipAddress: '192.168.1.43',
    );
    await addDevice(
      name: 'Bathroom Switch',
      type: DeviceType.switch,
      ipAddress: '192.168.1.44',
    );
    await addDevice(
      name: 'Garage Relay',
      type: DeviceType.relay,
      ipAddress: '192.168.1.45',
    );
  }

  // Toggle device on/off
  Future<void> toggleDevice(String deviceId) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;

    final device = _devices[index];
    final newState = !device.isOn;

    // Optimistic update
    _devices[index] = device.copyWith(isOn: newState, lastSeen: DateTime.now());
    _notify();

    try {
      if (_mockMode || device.isMock) {
        await _mockClient!.toggle(device.ipAddress);
      } else {
        await _getOrCreateClient(device).toggleRelay(channel: 0);
      }
      await _refreshDevice(device);
    } catch (e) {
      // Revert on failure
      _devices[index] = device;
      _notify();
      rethrow;
    }
  }

  // Turn device on
  Future<void> turnOn(String deviceId) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;

    final device = _devices[index];
    if (device.isOn) return;

    _devices[index] = device.copyWith(isOn: true, lastSeen: DateTime.now());
    _notify();

    try {
      if (_mockMode || device.isMock) {
        await _mockClient!.turnOn(device.ipAddress);
      } else {
        await _getOrCreateClient(device).turnOn(channel: 0);
      }
      await _refreshDevice(device);
    } catch (e) {
      _devices[index] = device;
      _notify();
      rethrow;
    }
  }

  // Turn device off
  Future<void> turnOff(String deviceId) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;

    final device = _devices[index];
    if (!device.isOn) return;

    _devices[index] = device.copyWith(isOn: false, lastSeen: DateTime.now());
    _notify();

    try {
      if (_mockMode || device.isMock) {
        await _mockClient!.turnOff(device.ipAddress);
      } else {
        await _getOrCreateClient(device).turnOff(channel: 0);
      }
      await _refreshDevice(device);
    } catch (e) {
      _devices[index] = device;
      _notify();
      rethrow;
    }
  }

  // Set brightness (lights)
  Future<void> setBrightness(String deviceId, int brightness) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;

    final device = _devices[index];
    _devices[index] = device.copyWith(brightness: brightness, isOn: brightness > 0, lastSeen: DateTime.now());
    _notify();

    try {
      if (_mockMode || device.isMock) {
        await _mockClient!.setBrightness(device.ipAddress, brightness);
      } else {
        if (brightness > 0 && !device.isOn) {
          await _getOrCreateClient(device).turnOn(channel: 0);
        } else if (brightness == 0 && device.isOn) {
          await _getOrCreateClient(device).turnOff(channel: 0);
        }
      }
      await _refreshDevice(device);
    } catch (e) {
      _devices[index] = device;
      _notify();
      rethrow;
    }
  }

  // Set color temperature (lights)
  Future<void> setTemperature(String deviceId, int temperature) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;

    final device = _devices[index];
    _devices[index] = device.copyWith(temperature: temperature.clamp(2700, 6500), lastSeen: DateTime.now());
    _notify();

    try {
      if (_mockMode || device.isMock) {
        await _mockClient!.setTemperature(device.ipAddress, temperature);
      } else {
        // Real device would use Light.Set RPC
      }
      await _refreshDevice(device);
    } catch (e) {
      _devices[index] = device;
      _notify();
      rethrow;
    }
  }

  // Set fan speed
  Future<void> setFanSpeed(String deviceId, int speed) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;

    final device = _devices[index];
    _devices[index] = device.copyWith(speed: speed, isOn: speed > 0, lastSeen: DateTime.now());
    _notify();

    try {
      if (_mockMode || device.isMock) {
        await _mockClient!.setSpeed(device.ipAddress, speed);
      } else {
        if (speed > 0 && !device.isOn) {
          await _getOrCreateClient(device).turnOn(channel: 0);
        } else if (speed == 0 && device.isOn) {
          await _getOrCreateClient(device).turnOff(channel: 0);
        }
      }
      await _refreshDevice(device);
    } catch (e) {
      _devices[index] = device;
      _notify();
      rethrow;
    }
  }

  // Refresh single device status
  Future<void> refreshDevice(String deviceId) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index < 0) return;
    await _refreshDevice(_devices[index]);
    _notify();
  }

  // Discover devices on network
  Future<List<Device>> discoverDevices() async {
    if (_mockMode) {
      // Use mock discovery in mock mode
      final found = await _mockClient!.discover();
      return _convertToDevices(found, isMock: true);
    } else {
      // Use real mDNS/SSDP discovery
      final discoveredDevices = await discoveryService.discover();
      return _convertToDevices(discoveredDevices, isMock: false);
    }
  }

  // Helper method to convert discovered devices to Device objects
  List<Device> _convertToDevices(List<DiscoveredDevice> discoveredDevices, {required bool isMock}) {
    final devices = <Device>[];

    for (final discoveredDevice in discoveredDevices) {
      // Check if already known
      final existingIndex = _devices.indexWhere((d) => d.ipAddress == discoveredDevice.ipAddress);
      if (existingIndex >= 0) {
        // Update existing device with latest info
        final updated = _devices[existingIndex].copyWith(
          status: discoveredDevice.isOnline ? DeviceStatus.online : DeviceStatus.offline,
          isOn: discoveredDevice.isOn,
          brightness: discoveredDevice.brightness,
          temperature: discoveredDevice.temperature,
          speed: discoveredDevice.speed,
          lastSeen: DateTime.now(),
          isMock: isMock,
        );
        _devices[existingIndex] = updated;
        devices.add(updated);
      } else {
        // Create new device
        final device = Device(
          id: _uuid.v4(),
          name: discoveredDevice.name,
          type: discoveredDevice.deviceType,
          ipAddress: discoveredDevice.ipAddress,
          status: discoveredDevice.isOnline ? DeviceStatus.online : DeviceStatus.offline,
          isOn: discoveredDevice.isOn,
          brightness: discoveredDevice.brightness,
          temperature: discoveredDevice.temperature,
          speed: discoveredDevice.speed,
          lastSeen: DateTime.now(),
          isMock: isMock,
        );
        _devices.add(device);
        devices.add(device);
      }
    }

    return devices;
  }

  // Refresh all devices
  Future<void> _refreshAllDevices() async {
    for (final device in _devices) {
      await _refreshDevice(device);
    }
    _notify();
  }

  // Refresh single device status
  Future<void> _refreshDevice(Device device) async {
    try {
      ShellySwitchState? state;
      ShellyGen1Relay? gen1State;
      MockDeviceState? mockState;

      if (_mockMode || device.isMock) {
        mockState = await _mockClient!.getStatus(device.ipAddress);
        if (mockState != null) {
          final index = _devices.indexWhere((d) => d.id == device.id);
          if (index >= 0) {
            _devices[index] = _devices[index].copyWith(
              status: mockState.online ? DeviceStatus.online : DeviceStatus.offline,
              isOn: mockState.isOn,
              brightness: mockState.brightness,
              temperature: mockState.temperature,
              speed: mockState.speed,
              lastSeen: DateTime.now(),
            );
          }
        }
      } else {
        final client = _getOrCreateClient(device);
        final generation = await client.detectGeneration();

        if (generation == ShellyGeneration.gen2) {
          state = await client.getRelayState(channel: 0);
        } else {
          final gen1Status = await client.gen1GetStatus();
          if (gen1Status.relays.isNotEmpty) {
            gen1State = gen1Status.relays.first;
          }
        }

        final index = _devices.indexWhere((d) => d.id == device.id);
        if (index >= 0) {
          bool isOn = false;
          double? power;

          if (state != null) {
            isOn = state.output;
            power = state.apower;
          } else if (gen1State != null) {
            isOn = gen1State.isOn;
            power = gen1State.power;
          }

          _devices[index] = _devices[index].copyWith(
            status: DeviceStatus.online,
            isOn: isOn,
            lastSeen: DateTime.now(),
          );
        }
      }
    } catch (e) {
      final index = _devices.indexWhere((d) => d.id == device.id);
      if (index >= 0) {
        _devices[index] = _devices[index].copyWith(
          status: DeviceStatus.offline,
          lastSeen: DateTime.now(),
        );
      }
    }
  }

  // Get or create HTTP client for device
  ShellyClient _getOrCreateClient(Device device) {
    final key = '${device.ipAddress}:${device.port}';
    if (!_realClients.containsKey(key)) {
      _realClients[key] = ShellyClient(
        baseUrl: 'http://${device.ipAddress}:${device.port}',
        timeout: const Duration(seconds: 5),
      );
    }
    return _realClients[key]!;
  }

  // Periodic status updates
  Future<void> _startPeriodicUpdates() async {
    Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_devices.isNotEmpty) {
        await _refreshAllDevices();
        _notify();
      }
    });
  }

  // Dispose
  void dispose() {
    _devicesController?.close();
    for (final client in _realClients.values) {
      client.dispose();
    }
    _realClients.clear();
  }
}