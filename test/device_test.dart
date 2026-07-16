import 'package:flutter_test/flutter_test.dart';
import 'package:lightfan_controller/models/device.dart';

void main() {
  group('Device Model', () {
    test('serializes and deserializes correctly', () {
      final device = Device(
        id: 'test-id',
        name: 'Living Room Light',
        type: DeviceType.light,
        ipAddress: '192.168.1.42',
        port: 80,
        status: DeviceStatus.online,
        isOn: true,
        brightness: 75,
        temperature: 4000,
      );

      final json = device.toJson();
      final restored = Device.fromJson(json);

      expect(restored.id, device.id);
      expect(restored.name, device.name);
      expect(restored.type, device.type);
      expect(restored.ipAddress, device.ipAddress);
      expect(restored.port, device.port);
      expect(restored.status, device.status);
      expect(restored.isOn, device.isOn);
      expect(restored.brightness, device.brightness);
      expect(restored.temperature, device.temperature);
    });

    test('copyWith preserves other fields', () {
      final device = Device(
        id: 'id',
        name: 'Test',
        type: DeviceType.fan,
        ipAddress: '10.0.0.1',
        isOn: false,
      );

      final updated = device.copyWith(isOn: true, speed: 2);

      expect(updated.isOn, true);
      expect(updated.speed, 2);
      expect(updated.name, 'Test');
      expect(updated.type, DeviceType.fan);
      expect(updated.ipAddress, '10.0.0.1');
      expect(updated.id, 'id');
    });

    test('displayType returns human readable name', () {
      expect(Device(id: '1', name: 'L', type: DeviceType.light, ipAddress: '1.1.1.1').displayType, 'Light');
      expect(Device(id: '1', name: 'F', type: DeviceType.fan, ipAddress: '1.1.1.1').displayType, 'Fan');
      expect(Device(id: '1', name: 'S', type: DeviceType.switch, ipAddress: '1.1.1.1').displayType, 'Switch');
      expect(Device(id: '1', name: 'R', type: DeviceType.relay, ipAddress: '1.1.1.1').displayType, 'Relay');
    });

    test('icon returns correct IconData per type', () {
      expect(Device(id: '1', name: 'L', type: DeviceType.light, ipAddress: '1.1.1.1').icon, Icons.lightbulb);
      expect(Device(id: '1', name: 'F', type: DeviceType.fan, ipAddress: '1.1.1.1').icon, Icons.air);
    });
  });
}
