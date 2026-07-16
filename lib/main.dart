import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/device.dart';
import 'services/device_service.dart';
import 'services/mock_shelly_client.dart';
import 'services/shelly_client.dart';
import 'screens/home_screen.dart';
import 'screens/add_device_screen.dart';
import 'screens/device_detail_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final deviceService = DeviceService(prefs);
  await deviceService.initialize();

  runApp(
    ChangeNotifierProvider.value(
      value: deviceService,
      child: const LightFanApp(),
    ),
  );
}

class LightFanApp extends StatelessWidget {
  const LightFanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LightFan Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      routes: {
        '/add-device': (context) => const AddDeviceScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/device-detail') {
          final device = settings.arguments as Device;
          return MaterialPageRoute(
            builder: (context) => DeviceDetailScreen(device: device),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}