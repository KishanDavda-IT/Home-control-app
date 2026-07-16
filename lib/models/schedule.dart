import 'package:flutter/material.dart';

enum ScheduleType {
  timer,      // Turn on/off after a duration
  schedule,   // Turn on/off at a specific time
  repeat,     // Repeat on specific days/times
  scene,      // Apply a predefined scene
}

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class Schedule {
  final String id;
  final String deviceId;
  final String name;
  final ScheduleType type;
  final DateTime createdAt;
  bool isEnabled;

  // For timer type
  final Duration? duration;

  // For schedule type
  final DateTime? scheduledTime;

  // For repeat type
  final List<DayOfWeek>? days;
  final TimeOfDay? time;

  // For scene type
  final Map<String, dynamic>? settings;

  Schedule({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.type,
    required this.createdAt,
    this.isEnabled = true,
    this.duration,
    this.scheduledTime,
    this.days,
    this.time,
    this.settings,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      type: ScheduleType.values.byName(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isEnabled: json['isEnabled'] as bool? ?? true,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'] as String)
          : null,
      days: json['days'] != null
          ? (json['days'] as List<dynamic>)
              .map((e) => DayOfWeek.values.byName(e as String))
              .toList()
          : null,
      time: json['time'] != null
          ? TimeOfDay(
              hour: (json['time'] as Map<String, dynamic>)['hour'] as int,
              minute: (json['time'] as Map<String, dynamic>)['minute'] as int,
            )
          : null,
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'name': name,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'isEnabled': isEnabled,
      'duration': duration?.inSeconds,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'days': days?.map((e) => e.name).toList(),
      'time': time != null
          ? {
              'hour': time!.hour,
              'minute': time!.minute,
            }
          : null,
      'settings': settings,
    };
  }

  Schedule copyWith({
    String? id,
    String? deviceId,
    String? name,
    ScheduleType? type,
    DateTime? createdAt,
    bool? isEnabled,
    Duration? duration,
    DateTime? scheduledTime,
    List<DayOfWeek>? days,
    TimeOfDay? time,
    Map<String, dynamic>? settings,
  }) {
    return Schedule(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isEnabled: isEnabled ?? this.isEnabled,
      duration: duration ?? this.duration,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      days: days ?? this.days,
      time: time ?? this.time,
      settings: settings ?? this.settings,
    );
  }
}

// A preset scene that can be applied to devices
class Scene {
  final String id;
  final String name;
  final String icon;
  final Color color;
  final Map<String, dynamic> settings; // Device-specific settings

  Scene({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.settings,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: Color(json['color'] as int),
      settings: Map<String, dynamic>.from(json['settings'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color.value,
      'settings': settings,
    };
  }
}