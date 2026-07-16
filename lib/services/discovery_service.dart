import 'dart:io';
import 'dart:async';
import 'package:mdns/mdns.dart' as mdns;
import '../models/device.dart';

/// Represents a discovered device on the network
class DiscoveredDevice {
  final String ipAddress;
  final String name;
  final DeviceType deviceType;
  final bool isOn;
  final bool isOnline;
  final int? brightness;
  final int? temperature;
  final int? speed;

  DiscoveredDevice({
    required this.ipAddress,
    required this.name,
    required this.deviceType,
    required this.isOn,
    required this.isOnline,
    this.brightness,
    this.temperature,
    this.speed,
  });
}

/// Service for discovering Shelly devices on the local network using mDNS/SSDP
class DiscoveryService {
  /// Discovers Shelly devices on the local network
  Future<List<DiscoveredDevice>> discover() async {
    final discoveredDevices = <DiscoveredDevice>[];

    try {
      // Try mDNS discovery first (works for many Shelly devices)
      final mdnsDevices = await _discoverViaMdns();
      discoveredDevices.addAll(mdnsDevices);

      // If no devices found via mDNS, try SSDP/UPnP
      if (discoveredDevices.isEmpty) {
        final ssdpDevices = await _discoverViaSsdp();
        discoveredDevices.addAll(ssdpDevices);
      }
    } catch (e) {
      // If discovery fails, return empty list (don't crash the app)
      debugPrint('Discovery error: $e');
    }

    return discoveredDevices;
  }

  /// Discover devices using mDNS (multicast DNS)
  Future<List<DiscoveredDevice>> _discoverViaMdns() async {
    final discoveredDevices = <DiscoveredDevice>[];

    try {
      // Look for common Shelly service types
      const serviceTypes = [
        '_http._tcp',           // General HTTP service
        '_http._tcp.local.',    // Local domain
        '_workstation._tcp',    // Common for devices
      ];

      for (final serviceType in serviceTypes) {
        try {
          final results = await mdns.lookup(serviceType);
          for (final service in results) {
            if (_isLikelyShellyDevice(service)) {
              final device = await _createDeviceFromMdnsService(service);
              if (device != null) {
                discoveredDevices.add(device);
              }
            }
          }
        } catch (e) {
          // Continue with other service types
          debugPrint('mDNS lookup failed for $serviceType: $e');
        }
      }
    } catch (e) {
      debugPrint('mDNS discovery error: $e');
    }

    return discoveredDevices;
  }

  /// Discover devices using SSDP (Simple Service Discovery Protocol)
  Future<List<DiscoveredDevice>> _discoverViaSsdp() async {
    // For now, we'll return an empty list as SSDP implementation is more complex
    // In a full implementation, you would:
    // 1. Send SSDP M-SEARCH multicast request
    // 2. Listen for responses from devices
    // 3. Parse the responses to extract device information
    // 4. Convert to DiscoveredDevice objects
    return [];
  }

  /// Check if an mDNS service is likely a Shelly device
  bool _isLikelyShellyDevice(mdns.Service service) {
    // Check hostname for common Shelly patterns
    final host = service.host.toLowerCase();
    if (host.contains('shelly') ||
        host.contains('shellyplus') ||
        host.contains('shelly1') ||
        host.contains('shelly2') ||
        host.contains('shellypm')) {
      return true;
    }

    // Check if any of the text records indicate a Shelly device
    for (final entry in service.txt.values) {
      final value = entry.toString().toLowerCase();
      if (value.contains('shelly') ||
          value.contains('shellyplus') ||
          value.contains('shelly1') ||
          value.contains('shelly2') ||
          value.contains('shellypm')) {
        return true;
      }
    }

    return false;
  }

  /// Create a DiscoveredDevice from an mDNS service
  Future<DiscoveredDevice?> _createDeviceFromMdnsService(mdns.Service service) async {
    try {
      // Extract IP address
      final ipAddress = service.addresses.firstOrNull?.toString();
      if (ipAddress == null) return null;

      // Extract device name from hostname or text records
      String name = service.host.split('.').first;
      if (name.isEmpty) name = 'Shelly Device';

      // Try to get a better name from text records
      final nameFromTxt = service.txt['name']?.toString() ??
                         service.txt['device_name']?.toString();
      if (nameFromTxt != null && nameFromTxt.isNotEmpty) {
        name = nameFromTxt;
      }

      // Determine device type based on name or service info
      DeviceType deviceType = DeviceType.relay; // Default
      final nameLower = name.toLowerCase();
      if (nameLower.contains('light') || nameLower.contains('bulb') || nameLower.contains('rgb')) {
        deviceType = DeviceType.light;
      } else if (nameLower.contains('fan') || nameLower.contains('vent')) {
        deviceType = DeviceType.fan;
      } else if (nameLower.contains('switch') || nameLower.contains('relay')) {
        deviceType = DeviceType.switch;
      } else if (nameLower.contains('relay') || nameLower.contains('outlet')) {
        deviceType = DeviceType.relay;
      }

      // Try to get device status by making an HTTP request
      final isOnline = await _checkDeviceOnline(ipAddress);
      bool isOn = false;
      int? brightness;
      int? temperature;
      int? speed;

      if (isOnline) {
        // Try to get actual device state
        try {
          final status = await _getDeviceStatus(ipAddress);
          isOn = status['isOn'] ?? false;
          brightness = status['brightness'];
          temperature = status['temperature'];
          speed = status['speed'];
        } catch (e) {
          // If we can't get status, assume it's on if we can reach it
          isOn = true;
        }
      }

      return DiscoveredDevice(
        ipAddress: ipAddress,
        name: name,
        deviceType: deviceType,
        isOn: isOn,
        isOnline: isOnline,
        brightness: brightness,
        temperature: temperature,
        speed: speed,
      );
    } catch (e) {
      debugPrint('Error creating device from mDNS service: $e');
      return null;
    }
  }

  /// Check if a device is online by attempting to connect
  Future<bool> _checkDeviceOnline(String ipAddress) async {
    try {
      final result = await Socket.connect(
        ipAddress,
        80,
        timeout: Duration(seconds: 3)
      );
      result.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get device status by querying the Shelly API
  Future<Map<String, dynamic>> _getDeviceStatus(String ipAddress) async {
    // This is a simplified implementation
    // In reality, you'd need to detect if it's Gen1 or Gen2 and call the appropriate endpoint
    try {
      // Try Gen2 RPC first
      final response = await HttpClient()
          .getUrl(Uri.parse('http://$ipAddress/rpc/Switch.GetStatus'))
          .then((request) => request.close())
          .then((response) => response.transform(utf8.decoder).join())
          .timeout(Duration(seconds: 3));

      // Parse the response to extract state
      // This would need proper JSON parsing based on Shelly's response format
      return {
        'isOn': true, // Placeholder
        'brightness': null,
        'temperature': null,
        'speed': null,
      };
    } catch (e) {
      // Try Gen1 status endpoint
      try {
        final response = await HttpClient()
            .getUrl(Uri.parse('http://$ipAddress/status'))
            .then((request) => request.close())
            .then((response) => response.transform(utf8.decoder).join())
            .timeout(Duration(seconds: 3));

        // Parse Gen1 response
        return {
          'isOn': true, // Placeholder
          'brightness': null,
          'temperature': null,
          'speed': null,
        };
      } catch (e2) {
        // If both fail, return default values
        return {
          'isOn': false,
          'brightness': null,
          'temperature': null,
          'speed': null,
        };
      }
    }
  }
}