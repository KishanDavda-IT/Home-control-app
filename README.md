# LightFan Controller


A Flutter app to control **Shelly** smart lights, fans, switches, and relays on your **local network** — no cloud, no account, works offline.

> **Note on hardware:** This app is the *controller*. To actually switch a real light or fan, each point needs a Shelly relay (e.g. Shelly 1, Plus 1PM, or a smart plug) wired in. Software alone cannot open a physical circuit — the Shelly is the bridge.

## Features

- 💡 Control lights (on/off, brightness, color temperature)
- 🌀 Control fans (on/off, speed 0–4)
- 🔘 Control switches and relays
- 🔍 Auto-discovery of Shelly devices on your LAN
- 💾 Local persistence (your devices stay on your phone)
- 🧪 **Mock mode** — fully functional UI without any hardware, for development/testing
- 🌓 Light/Dark theme following system preference
- 📱 Material Design 3 with modern UI

## Architecture

```
UI (screens: Home grid, Add/Edit, Detail, Settings)
        │  Provider (ChangeNotifier)
State ── DeviceService (persistence + orchestration)
        │
        ├── MockShellyClient  (simulated devices, no hardware)
        └── ShellyClient       (real HTTP: Gen2 RPC + Gen1 REST)
                    │
              Shelly device on LAN (http://<ip>/rpc/...)
```

- **`models/device.dart`** — `Device` entity (type, IP, status, on/off, brightness, temp, speed)
- **`services/shelly_client.dart`** — real Shelly API client. Auto-detects Gen1 vs Gen2 and uses the right endpoint (`/rpc/Switch.Set` for Gen2, `/relay/<n>?turn=...` for Gen1)
- **`services/mock_shelly_client.dart`** — simulates multiple devices with latency/state, so the whole app works with zero hardware
- **`services/device_service.dart`** — `ChangeNotifier` holding the device list, saving to `shared_preferences`, optimistic toggles, periodic refresh, discovery
- **`screens/`** — `HomeScreen` (grouped grid + pull-to-refresh), `AddDeviceScreen`, `DeviceDetailScreen`, `SettingsScreen`
- **`widgets/`** — `DeviceCard`, `EmptyState`

## Setup

### 1. Install Flutter (Windows/macOS/Linux)

If you don't have it, download the stable SDK and add `<flutter>/bin` to your `PATH`. Then:

```bash
flutter doctor
```

Resolve any items (Android SDK for Android builds; iOS requires a Mac with Xcode).

### 2. Get dependencies

```bash
cd lightfan-controller
flutter pub get
```

### 3. Run in Mock Mode (no hardware needed)

```bash
flutter run
```

Open **Settings → Mock Mode** (on by default) → **Add Demo Devices**, or tap **+** and use a Quick-Add chip. You can toggle, dim, and change fan speed immediately.

### 4. Connect real Shelly hardware

1. Put your Shelly on the same WiFi as your phone.
2. Find its IP (Shelly app, or router DHCP list).
3. In this app: **Settings → Mock Mode → OFF**.
4. **+ → Add Device** → enter name, type, IP → **Test Connection** → **Save**.
5. Toggle it from the home grid.

> **Android cleartext note:** Local Shelly talks plain HTTP. `android/app/src/main/AndroidManifest.xml` already sets `usesCleartextTraffic="true"`. iOS `Info.plist` includes the local-network usage description.

## Testing

```bash
# Run all unit tests
flutter test

# Run a single test file
flutter test test/device_test.dart

# Static analysis / lint
flutter analyze
```

## Building

```bash
flutter build apk        # Android
flutter build ios        # iOS (needs macOS + Xcode)
flutter build web        # Web
flutter build macos      # macOS
flutter build windows    # Windows
flutter build linux      # Linux
```

## Project Layout

```
lib/
  main.dart
  models/device.dart
  services/{shelly_client,mock_shelly_client,device_service}.dart
  screens/{home,add_device,device_detail,settings}_screen.dart
  widgets/{device_card,empty_state}.dart
test/
  device_test.dart
  mock_shelly_client_test.dart
pubspec.yaml
```

## To-do / Not yet wired

- [ ] Real mDNS/SSDP discovery (currently mock-only; manual add works for real devices)
- [ ] Scheduling / timers / scenes
- [ ] Home-screen quick widget / notification toggle
- [ ] Per-device credentials for Shelly auth
- [ ] Energy monitoring visualization
- [ ] OTA update notifications for Shelly devices
- [ ] Group control for multiple devices

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Shelly](https://shelly.cloud/) for their excellent local API
- The Flutter team for the amazing framework
- All contributors who help make this project better
