import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';
import '../models/device.dart';

class ScheduleService {
  static const String _schedulesKey = 'schedules';
  static const String _scenesKey = 'scenes';

  final SharedPreferences _prefs;
  Timer? _timer;

  List<Schedule> _schedules = [];
  List<Scene> _scenes = [];
  StreamController<List<Schedule>>? _schedulesController;
  StreamController<List<Scene>>? _scenesController;

  ScheduleService(this._prefs) {
    _loadSchedules();
    _loadScenes();
    _startScheduleChecker();
  }

  Stream<List<Schedule>> get schedulesStream {
    _schedulesController ??= StreamController<List<Schedule>>.broadcast();
    return _schedulesController!.stream;
  }

  Stream<List<Scene>> get scenesStream {
    _scenesController ??= StreamController<List<Scene>>.broadcast();
    return _scenesController!.stream;
  }

  List<Schedule> get schedules => List.unmodifiable(_schedules);
  List<Scene> get scenes => List.unmodifiable(_scenes);

  // Load schedules from prefs
  void _loadSchedules() {
    final jsonString = _prefs.getString(_schedulesKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _schedules = jsonList.map((j) => Schedule.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        _schedules = [];
      }
    }
  }

  // Save schedules to prefs
  Future<void> _saveSchedules() async {
    final jsonString = jsonEncode(_schedules.map((s) => s.toJson()).toList());
    await _prefs.setString(_schedulesKey, jsonString);
    _schedulesController?.add(List.unmodifiable(_schedules));
  }

  // Load scenes from prefs
  void _loadScenes() {
    final jsonString = _prefs.getString(_scenesKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _scenes = jsonList.map((j) => Scene.fromJson(j as Map<String, dynamic>)).toList();
      } catch (e) {
        _scenes = [];
      }
    }
  }

  // Save scenes to prefs
  Future<void> _saveScenes() async {
    final jsonString = jsonEncode(_scenes.map((s) => s.toJson()).toList());
    await _prefs.setString(_scenesKey, jsonString);
    _scenesController?.add(List.unmodifiable(_scenes));
  }

  // Add a new schedule
  Future<Schedule> addSchedule(Schedule schedule) async {
    _schedules.add(schedule);
    await _saveSchedules();
    return schedule;
  }

  // Update an existing schedule
  Future<void> updateSchedule(Schedule schedule) async {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      _schedules[index] = schedule;
      await _saveSchedules();
    }
  }

  // Remove a schedule
  Future<void> removeSchedule(String scheduleId) async {
    _schedules.removeWhere((s) => s.id == scheduleId);
    await _saveSchedules();
  }

  // Add a new scene
  Future<Scene> addScene(Scene scene) async {
    _scenes.add(scene);
    await _saveScenes();
    return scene;
  }

  // Update an existing scene
  Future<void> updateScene(Scene scene) async {
    final index = _scenes.indexWhere((s) => s.id == scene.id);
    if (index >= 0) {
      _scenes[index] = scene;
      await _saveScenes();
    }
  }

  // Remove a scene
  Future<void> removeScene(String sceneId) async {
    _scenes.removeWhere((s) => s.id == sceneId);
    await _saveScenes();
  }

  // Enable/disable a schedule
  Future<void> toggleSchedule(String scheduleId, bool enabled) async {
    final index = _schedules.indexWhere((s) => s.id == scheduleId);
    if (index >= 0) {
      _schedules[index] = _schedules[index].copyWith(isEnabled: enabled);
      await _saveSchedules();
    }
  }

  // Check for scheduled tasks that need to be executed
  void _startScheduleChecker() {
    // Check every minute for scheduled tasks
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkScheduledTasks());
  }

  void _checkScheduledTasks() {
    final now = DateTime.now();
    final dayOfWeek = _getDayOfWeek(now.weekday);

    for (final schedule in _schedules.where((s) => s.isEnabled)) {
      switch (schedule.type) {
        case ScheduleType.timer:
          // Timers are handled differently - they're usually one-shot
          break;
        case ScheduleType.schedule:
          if (schedule.scheduledTime != null) {
            final scheduledDate = schedule.scheduledTime!;
            // Check if it's time to execute (within the minute window)
            if (_isSameMinute(now, scheduledDate)) {
              _executeSchedule(schedule);
              // Disable one-time schedules after execution
              final index = _schedules.indexWhere((s) => s.id == schedule.id);
              if (index != -1) {
                _schedules[index] = _schedules[index].copyWith(isEnabled: false);
                _saveSchedules();
              }
            }
          }
          break;
        case ScheduleType.repeat:
          if (schedule.days != null &&
              schedule.time != null &&
              schedule.days!.contains(dayOfWeek)) {
            final scheduledToday = DateTime(
              now.year,
              now.month,
              now.day,
              schedule.time!.hour,
              schedule.time!.minute,
            );
            if (_isSameMinute(now, scheduledToday)) {
              _executeSchedule(schedule);
            }
          }
          break;
        case ScheduleType.scene:
          // Scenes are triggered manually, not automatically
          break;
      }
    }
  }

  bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  DayOfWeek _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return DayOfWeek.monday;
      case DateTime.tuesday:
        return DayOfWeek.tuesday;
      case DateTime.wednesday:
        return DayOfWeek.wednesday;
      case DateTime.thursday:
        return DayOfWeek.thursday;
      case DateTime.friday:
        return DayOfWeek.friday;
      case DateTime.saturday:
        return DayOfWeek.saturday;
      case DateTime.sunday:
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }

  // Execute a schedule (turn device on/off, set brightness, etc.)
  Future<void> _executeSchedule(Schedule schedule) async {
    // In a real implementation, this would communicate with the device
    // For now, we'll just log it
    print('Executing schedule: ${schedule.name} for device: ${schedule.deviceId}');

    // TODO: Implement actual device control based on schedule settings
    // This would involve calling the DeviceService to turn on/off, set brightness, etc.
  }

  // Dispose resources
  void dispose() {
    _schedulesController?.close();
    _scenesController?.close();
    _timer?.cancel();
  }
}