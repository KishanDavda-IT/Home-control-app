import 'dart:async';
import 'dart:math';
import '../models/device.dart';

/// Mock Shelly client that simulates device behavior for testing without hardware.
/// Simulates network latency, device state persistence, and discovery.
class MockShellyClient {
  final Map<String, MockDeviceState> _devices = {};
  final Random _random = Random();
  final Duration simulatedLatency = const Duration(milliseconds: 150);

  MockShellyClient() {
    _seedMockDevices();
  }

  void _seedMockDevices() {
    // Simulate a few typical devices on the network
    _devices['192.168.1.42'] = MockDeviceState(
      ip: '192.168.1.42',
      name: 'Living Room Light',
      type: DeviceType.light,
      isOn: false,
      brightness: 80,
      temperature: 4000,
    );
    _devices['192.168.1.43'] = MockDeviceState(
      ip: '192.168.1.43',
      name: 'Bedroom Fan',
      type: DeviceType.fan,
      isOn: true,
      speed: 3,
    );
    _devices['192.168.1.44'] = MockDeviceState(
      ip: '192.168.1.44',
      name: 'Bathroom Switch',
      type: DeviceType.switch,
      isOn: false,
    );
    _devices['192.168.1.45'] = MockDeviceState(
      ip: '192.168.1.45',
      name: 'Garage Relay',
      type: DeviceType.relay,
      isOn: true,
    );
  }

  Future<void> _delay() async {
    await Future.delayed(
      Duration(milliseconds: simulatedLatency.inMilliseconds + _random.nextInt(100)),
    );
  }

  // Discovery - simulates mDNS/SSDP scan
  Future<List<MockDeviceState>> discover({Duration timeout = const Duration(seconds: 3)}) async {
    await _delay();
    // Simulate some devices being "offline" occasionally
    return _devices.values.where((d) => _random.nextDouble() > 0.1).toList();
  }

  // Get status for a specific IP
  Future<MockDeviceState?> getStatus(String ip) async {
    await _delay();
    return _devices[ip]?.copyWith(lastSeen: DateTime.now());
  }

  // Toggle device
  Future<MockDeviceState> toggle(String ip) async {
    await _delay();
    final device = _devices[ip];
    if (device == null) throw MockShellyError.notFound;
    final updated = device.copyWith(isOn: !device.isOn);
    _devices[ip] = updated;
    return updated;
  }

  // Turn on
  Future<MockDeviceState> turnOn(String ip) async {
    await _delay();
    final device = _devices[ip];
    if (device == null) throw MockShellyError.notFound;
    final updated = device.copyWith(isOn: true);
    _devices[ip] = updated;
    return updated;
  }

  // Turn off
  Future<MockDeviceState> turnOff(String ip) async {
    await _delay();
    final device = _devices[ip];
    if (device == null) throw MockShellyError.notFound;
    final updated = device.copyWith(isOn: false);
    _devices[ip] = updated;
    return updated;
  }

  // Set brightness (for lights)
  Future<MockDeviceState> setBrightness(String ip, int brightness) async {
    await _delay();
    final device = _devices[ip];
    if (device == null) throw MockShellyError.notFound;
    final updated = device.copyWith(brightness: brightness.clamp(0, 100), isOn: brightness > 0);
    _devices[ip] = updated;
    return updated;
  }

  // Set color temperature (for lights)
  Future<MockDeviceState> setTemperature(String ip, int temperature) async {
    await _delay();
    final device = _devices[ip];
    if (device == null) throw MockShellyError.notFound;
    final updated = device.copyWith(temperature: temperature.clamp(2700, 6500));
    _devices[ip] = updated;
    return updated;
  }

  // Set fan speed
  Future<MockDeviceState> setSpeed(String ip, int speed) async {
    await _delay();
    final device = _devices[ip];
    if (device == null) throw MockShellyError.notFound;
    final updated = device.copyWith(speed: speed.clamp(0, 4), isOn: speed > 0);
    _devices[ip] = updated;
    return updated;
  }

  // Get device info (Gen2 style)
  Future<MockDeviceInfo> getDeviceInfo(String ip) async {
    await _delay();
    final device = _devices[ip];
    if (device == null) throw MockShellyError.notFound;
    return MockDeviceInfo(
      name: device.name,
      mac: 'AA:BB:CC:${_random.nextInt(256).toRadixString(16).padLeft(2, '0')}:${_random.nextInt(256).toRadixString(16).padLeft(2, '0')}:${_random.nextInt(256).toRadixString(16).padLeft(2, '0')}',
      firmware: '20240101-000000',
      model: _modelForType(device.type),
      gen: 2,
    );
  }

  String _modelForType(DeviceType type) {
    switch (type) {
      case DeviceType.light:
        return 'Shelly RGBW2';
      case DeviceType.fan:
        return 'Shelly Plus 2PM';
      case DeviceType.switch:
        return 'Shelly 1';
      case DeviceType.relay:
        return 'Shelly Plus 1';
    }
  }

  // Add a custom mock device (for testing)
  void addMockDevice(MockDeviceState device) {
    _devices[device.ip] = device;
  }

  // Remove a mock device
  void removeMockDevice(String ip) {
    _devices.remove(ip);
  }

  // Get all known devices
  List<MockDeviceState> getAllDevices() => _devices.values.toList();

  // Reset to seed state
  void reset() {
    _devices.clear();
    _seedMockDevices();
  }
}

class MockDeviceState {
  final String ip;
  final String name;
  final DeviceType type;
  final bool isOn;
  final int? brightness;
  final int? temperature;
  final int? speed;
  final DateTime lastSeen;
  final bool online;

  MockDeviceState({
    required this.ip,
    required this.name,
    required this.type,
    required this.isOn,
    this.brightness,
    this.temperature,
    this.speed,
    DateTime? lastSeen,
    this.online = true,
  }) : lastSeen = lastSeen ?? DateTime.now();

  MockDeviceState copyWith({
    String? ip,
    String? name,
    DeviceType? type,
    bool? isOn,
    int? brightness,
    int? temperature,
    int? speed,
    DateTime? lastSeen,
    bool? online,
  }) {
    return MockDeviceState(
      ip: ip ?? this.ip,
      name: name ?? this.name,
      type: type ?? this.type,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      temperature: temperature ?? this.temperature,
      speed: speed ?? this.speed,
      lastSeen: lastSeen ?? this.lastSeen,
      online: online ?? this.online,
    );
  }

  Map<String, dynamic> toJson() => {
        'ip': ip,
        'name': name,
        'type': type.name,
        'isOn': isOn,
        'brightness': brightness,
        'temperature': temperature,
        'speed': speed,
        'lastSeen': lastSeen.toIso8601String(),
        'online': online,
      };
}

class MockDeviceInfo {
  final String name;
  final String mac;
  final String firmware;
  final String model;
  final int gen;

  MockDeviceInfo({
    required this.name,
    required this.mac,
    required this.firmware,
    required this.model,
    required this.gen,
  });
}

enum MockShellyError { notFound, timeout, offline }

extension MockShellyErrorExt on MockShellyError {
  String get message {
    switch (this) {
      case MockShellyError.notFound:
        return 'Device not found';
      case MockShellyError.timeout:
        return 'Request timeout';
      case MockShellyError.offline:
        return 'Device offline';
    }
  }
}