import 'package:flutter/material.dart';

enum DeviceType {
  light,
  fan,
  switch,
  relay,
}

enum DeviceStatus {
  online,
  offline,
  unknown,
}

class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String ipAddress;
  final int port;
  final String? macAddress;
  final DeviceStatus status;
  final bool isOn;
  final int? brightness;
  final int? temperature;
  final int? speed;
  final DateTime lastSeen;
  final bool isMock;
  final String? username;
  final String? password;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.ipAddress,
    this.port = 80,
    this.macAddress,
    this.status = DeviceStatus.unknown,
    this.isOn = false,
    this.brightness,
    this.temperature,
    this.speed,
    DateTime? lastSeen,
    this.isMock = false,
    this.username,
    this.password,
  }) : lastSeen = lastSeen ?? DateTime.now();

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      type: DeviceType.values.byName(json['type'] as String),
      ipAddress: json['ipAddress'] as String,
      port: json['port'] as int? ?? 80,
      macAddress: json['macAddress'] as String?,
      status: DeviceStatus.values.byName(json['status'] as String? ?? 'unknown'),
      isOn: json['isOn'] as bool? ?? false,
      brightness: json['brightness'] as int?,
      temperature: json['temperature'] as int?,
      speed: json['speed'] as int?,
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ?? DateTime.now(),
      isMock: json['isMock'] as bool? ?? false,
      username: json['username'] as String?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'ipAddress': ipAddress,
      'port': port,
      'macAddress': macAddress,
      'status': status.name,
      'isOn': isOn,
      'brightness': brightness,
      'temperature': temperature,
      'speed': speed,
      'lastSeen': lastSeen.toIso8601String(),
      'isMock': isMock,
      'username': username,
      'password': password,
    };
  }

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? ipAddress,
    int? port,
    String? macAddress,
    DeviceStatus? status,
    bool? isOn,
    int? brightness,
    int? temperature,
    int? speed,
    DateTime? lastSeen,
    bool? isMock,
    String? username,
    String? password,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      macAddress: macAddress ?? this.macAddress,
      status: status ?? this.status,
      isOn: isOn ?? this.isOn,
      brightness: brightness ?? this.brightness,
      temperature: temperature ?? this.temperature,
      speed: speed ?? this.speed,
      lastSeen: lastSeen ?? this.lastSeen,
      isMock: isMock ?? this.isMock,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  String get displayType {
    switch (type) {
      case DeviceType.light:
        return 'Light';
      case DeviceType.fan:
        return 'Fan';
      case DeviceType.switch:
        return 'Switch';
      case DeviceType.relay:
        return 'Relay';
    }
  }

  IconData get icon {
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

  Color get typeColor {
    switch (type) {
      case DeviceType.light:
        return Colors.amber;
      case DeviceType.fan:
        return Colors.blue;
      case DeviceType.switch:
        return Colors.green;
      case DeviceType.relay:
        return Colors.orange;
    }
  }
}