import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'pages/settings.dart';
import 'pages/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.loadSettings(); // Load persistent settings.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the user changes the themeMode in AppSettings
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeModeNotifier,
      builder: (context, themeMode, child) {
        return DynamicColorBuilder(
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            final ColorScheme lightScheme = lightDynamic?.harmonized() ??
                ColorScheme.fromSeed(seedColor: Colors.blue);
            final ColorScheme darkScheme = darkDynamic?.harmonized() ??
                ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                );

            return MaterialApp(
              title: 'Kraken',
              themeMode: themeMode,
              theme: ThemeData(
                colorScheme: lightScheme,
                useMaterial3: true,
              ),
              darkTheme: ThemeData(
                colorScheme: darkScheme,
                useMaterial3: true,
              ),
              home: const MainPage(),
            );
          },
        );
      },
    );
  }
}
