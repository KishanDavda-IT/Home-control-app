import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum ShellyGeneration { gen1, gen2, unknown }

class ShellySwitchState {
  final bool output;
  final double? apower;
  final double? voltage;
  final double? current;
  final double? temperature;
  final bool? overpower;

  ShellySwitchState({
    required this.output,
    this.apower,
    this.voltage,
    this.current,
    this.temperature,
    this.overpower,
  });

  factory ShellySwitchState.fromJson(Map<String, dynamic> json) {
    return ShellySwitchState(
      output: json['output'] ?? false,
      apower: (json['apower'] as num?)?.toDouble(),
      voltage: (json['voltage'] as num?)?.toDouble(),
      current: (json['current'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      overpower: json['overpower'] as bool?,
    );
  }
}

class ShellyGen1Relay {
  final bool isOn;
  final double? power;
  final double? energy;
  final bool? overpower;

  ShellyGen1Relay({
    required this.isOn,
    this.power,
    this.energy,
    this.overpower,
  });

  factory ShellyGen1Relay.fromJson(Map<String, dynamic> json) {
    return ShellyGen1Relay(
      isOn: json['ison'] ?? false,
      power: (json['power'] as num?)?.toDouble(),
      energy: (json['energy'] as num?)?.toDouble(),
      overpower: json['overpower'] as bool?,
    );
  }
}

class ShellyGen1Status {
  final List<ShellyGen1Relay> relays;
  final double? totalPower;
  final String? wifiStatus;
  final int? uptime;

  ShellyGen1Status({
    required this.relays,
    this.totalPower,
    this.wifiStatus,
    this.uptime,
  });

  factory ShellyGen1Status.fromJson(Map<String, dynamic> json) {
    final relaysJson = json['relays'] as List<dynamic>? ?? [];
    return ShellyGen1Status(
      relays: relaysJson.map((r) => ShellyGen1Relay.fromJson(r as Map<String, dynamic>)).toList(),
      totalPower: (json['total_power'] as num?)?.toDouble(),
      wifiStatus: json['wifi_sta']?['status'] as String?,
      uptime: json['uptime'] as int?,
    );
  }
}

class ShellyDeviceInfo {
  final String name;
  final String mac;
  final String firmware;
  final String model;
  final int gen;

  ShellyDeviceInfo({
    required this.name,
    required this.mac,
    required this.firmware,
    required this.model,
    required this.gen,
  });

  factory ShellyDeviceInfo.fromJsonGen1(Map<String, dynamic> json) {
    return ShellyDeviceInfo(
      name: json['device']?['name'] ?? json['name'] ?? 'Shelly',
      mac: json['wifi_sta']?['mac'] ?? '',
      firmware: json['fw'] ?? '',
      model: json['device']?['type'] ?? '',
      gen: 1,
    );
  }

  factory ShellyDeviceInfo.fromJsonGen2(Map<String, dynamic> json) {
    return ShellyDeviceInfo(
      name: json['name'] ?? 'Shelly',
      mac: json['mac'] ?? '',
      firmware: json['fw_id'] ?? '',
      model: json['model'] ?? '',
      gen: 2,
    );
  }
}

class ShellyClient {
  final String baseUrl;
  final Duration timeout;
  final String? username;
  final String? password;
  http.Client? _client;

  ShellyClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 5),
    this.username,
    this.password,
  });

  http.Client get _http => _client ??= http.Client();

  // Detect device generation
  Future<ShellyGeneration> detectGeneration() async {
    try {
      // Try Gen2 RPC first
      final resp = await _http.post(
        Uri.parse('$authenticatedBaseUrl/rpc/Shelly.GetDeviceInfo'),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        return ShellyGeneration.gen2;
      }
    } catch (_) {}

    try {
      // Try Gen1 status endpoint
      final resp = await _http.get(Uri.parse('$authenticatedBaseUrl/status')).timeout(timeout);
      if (resp.statusCode == 200) {
        return ShellyGeneration.gen1;
      }
    } catch (_) {}

    return ShellyGeneration.unknown;
  }

  String get authenticatedBaseUrl {
    if (username != null && password != null) {
      // Format: http://username:password@host:port
      final uri = Uri.parse(baseUrl);
      return uri.replace(
        userInfo: '$username:$password',
      ).toString();
    }
    return baseUrl;
  }

  // Gen2: Get device info
  Future<ShellyDeviceInfo> getDeviceInfo() async {
    final resp = await _http.post(
      Uri.parse('$authenticatedBaseUrl/rpc/Shelly.GetDeviceInfo'),
      headers: {'Content-Type': 'application/json'},
      body: '{}',
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to get device info: ${resp.statusCode}');
    }

    return ShellyDeviceInfo.fromJsonGen2(jsonDecode(resp.body));
  }

  // Gen2: Get relay/switch state
  Future<ShellySwitchState> getRelayState({int channel = 0}) async {
    final resp = await _http.post(
      Uri.parse('$authenticatedBaseUrl/rpc/Switch.GetStatus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': channel}),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to get relay state: ${resp.statusCode}');
    }

    return ShellySwitchState.fromJson(jsonDecode(resp.body));
  }

  // Gen2: Turn on
  Future<void> turnOn({int channel = 0}) async {
    final resp = await _http.post(
      Uri.parse('$authenticatedBaseUrl/rpc/Switch.Set'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': channel, 'on': true}),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to turn on: ${resp.statusCode}');
    }
  }

  // Gen2: Turn off
  Future<void> turnOff({int channel = 0}) async {
    final resp = await _http.post(
      Uri.parse('$authenticatedBaseUrl/rpc/Switch.Set'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': channel, 'on': false}),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to turn off: ${resp.statusCode}');
    }
  }

  // Gen2: Toggle
  Future<void> toggleRelay({int channel = 0}) async {
    final resp = await _http.post(
      Uri.parse('$authenticatedBaseUrl/rpc/Switch.Toggle'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': channel}),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to toggle: ${resp.statusCode}');
    }
  }

  // Gen2: Set brightness (for lights)
  Future<void> setBrightness(int channel, int brightness) async {
    // brightness 0-100
    final resp = await _http.post(
      Uri.parse('$authenticatedBaseUrl/rpc/Light.Set'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': channel, 'brightness': brightness, 'on': brightness > 0}),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to set brightness: ${resp.statusCode}');
    }
  }

  // Gen1: Get status
  Future<ShellyGen1Status> gen1GetStatus() async {
    final resp = await _http.get(Uri.parse('$authenticatedBaseUrl/status')).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to get Gen1 status: ${resp.statusCode}');
    }

    return ShellyGen1Status.fromJson(jsonDecode(resp.body));
  }

  // Gen1: Turn on relay
  Future<void> gen1TurnOn({int channel = 0}) async {
    final resp = await _http.get(
      Uri.parse('$authenticatedBaseUrl/relay/$channel?turn=on'),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to turn on Gen1: ${resp.statusCode}');
    }
  }

  // Gen1: Turn off relay
  Future<void> gen1TurnOff({int channel = 0}) async {
    final resp = await _http.get(
      Uri.parse('$authenticatedBaseUrl/relay/$channel?turn=off'),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to turn off Gen1: ${resp.statusCode}');
    }
  }

  // Gen1: Toggle relay
  Future<void> gen1Toggle({int channel = 0}) async {
    final resp = await _http.get(
      Uri.parse('$authenticatedBaseUrl/relay/$channel?turn=toggle'),
    ).timeout(timeout);

    if (resp.statusCode != 200) {
      throw ShellyException('Failed to toggle Gen1: ${resp.statusCode}');
    }
  }

  // Generic toggle (tries Gen2 first, falls back to Gen1)
  Future<void> toggleRelay({int channel = 0}) async {
    final gen = await detectGeneration();
    if (gen == ShellyGeneration.gen2) {
      await toggleRelay(channel: channel);
    } else {
      await gen1Toggle(channel: channel);
    }
  }

  // Generic turn on
  Future<void> turnOn({int channel = 0}) async {
    final gen = await detectGeneration();
    if (gen == ShellyGeneration.gen2) {
      await turnOn(channel: channel);
    } else {
      await gen1TurnOn(channel: channel);
    }
  }

  // Generic turn off
  Future<void> turnOff({int channel = 0}) async {
    final gen = await detectGeneration();
    if (gen == ShellyGeneration.gen2) {
      await turnOff(channel: channel);
    } else {
      await gen1TurnOff(channel: channel);
    }
  }

  void dispose() {
    _client?.close();
    _client = null;
  }
}

class ShellyException implements Exception {
  final String message;
  ShellyException(this.message);
  @override
  String toString() => 'ShellyException: $message';
}