import 'package:flutter_test/flutter_test.dart';
import 'package:lightfan_controller/services/mock_shelly_client.dart';

void main() {
  group('MockShellyClient', () {
    late MockShellyClient client;

    setUp(() {
      client = MockShellyClient();
    });

    test('seeds default mock devices', () {
      final devices = client.getAllDevices();
      expect(devices.length, greaterThanOrEqualTo(4));
      expect(devices.any((d) => d.ip == '192.168.1.42'), isTrue);
      expect(devices.any((d) => d.ip == '192.168.1.43'), isTrue);
    });

    test('toggle flips on/off state', () async {
      final before = await client.getStatus('192.168.1.42');
      expect(before, isNotNull);

      final after = await client.toggle('192.168.1.42');
      expect(after.isOn, !before!.isOn);

      // toggle back
      final after2 = await client.toggle('192.168.1.42');
      expect(after2.isOn, before.isOn);
    });

    test('turnOn sets isOn true', () async {
      final result = await client.turnOn('192.168.1.42');
      expect(result.isOn, isTrue);
    });

    test('turnOff sets isOn false', () async {
      final result = await client.turnOff('192.168.1.42');
      expect(result.isOn, isFalse);
    });

    test('setBrightness clamps 0-100 and turns off at 0', () async {
      final low = await client.setBrightness('192.168.1.42', 0);
      expect(low.isOn, isFalse);
      expect(low.brightness, 0);

      final high = await client.setBrightness('192.168.1.42', 150);
      expect(high.brightness, 100);
      expect(high.isOn, isTrue);
    });

    test('setTemperature clamps 2700-6500', () async {
      final cold = await client.setTemperature('192.168.1.42', 1000);
      expect(cold.temperature, 2700);

      final hot = await client.setTemperature('192.168.1.42', 9000);
      expect(hot.temperature, 6500);
    });

    test('setSpeed clamps 0-4', () async {
      final zero = await client.setSpeed('192.168.1.43', 0);
      expect(zero.speed, 0);
      expect(zero.isOn, isFalse);

      final max = await client.setSpeed('192.168.1.43', 10);
      expect(max.speed, 4);
      expect(max.isOn, isTrue);
    });

    test('getStatus returns null for unknown IP', () async {
      final result = await client.getStatus('192.168.999.999');
      expect(result, isNull);
    });

    test('toggle throws for unknown IP', () async {
      expect(
        () => client.toggle('192.168.999.999'),
        throwsA(isA<MockShellyError>()),
      );
    });

    test('discover returns seeded devices', () async {
      final found = await client.discover();
      expect(found, isNotEmpty);
      expect(found.every((d) => d.ip.isNotEmpty), isTrue);
    });
  });
}
