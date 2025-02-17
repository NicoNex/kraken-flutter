import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeChoice { system, light, dark }

class AppSettings {
  static const String keyBaseUrl = 'base_url';
  static const String keyThemeMode = 'theme_mode';

  static String baseUrl = 'https://ukraken.dobl.one';
  // A ValueNotifier to automatically notify listeners when themeMode changes.
  static ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  static ThemeMode get themeMode => themeModeNotifier.value;
  static set themeMode(ThemeMode value) {
    themeModeNotifier.value = value;
  }

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString(keyBaseUrl) ?? 'https://ukraken.dobl.one';
    final themeString = prefs.getString(keyThemeMode) ?? 'system';
    switch (themeString) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
    }
  }

  static Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, baseUrl);
    String themeString;
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      default:
        themeString = 'system';
    }
    await prefs.setString(keyThemeMode, themeString);
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _baseUrlController;
  ThemeChoice _themeChoice = ThemeChoice.system;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: AppSettings.baseUrl);
    switch (AppSettings.themeMode) {
      case ThemeMode.light:
        _themeChoice = ThemeChoice.light;
        break;
      case ThemeMode.dark:
        _themeChoice = ThemeChoice.dark;
        break;
      default:
        _themeChoice = ThemeChoice.system;
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    super.dispose();
  }

  void _updateThemeChoice(ThemeChoice value) {
    setState(() {
      _themeChoice = value;
      switch (_themeChoice) {
        case ThemeChoice.light:
          AppSettings.themeMode = ThemeMode.light;
          break;
        case ThemeChoice.dark:
          AppSettings.themeMode = ThemeMode.dark;
          break;
        default:
          AppSettings.themeMode = ThemeMode.system;
      }
      AppSettings.saveSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: "Base URL",
                hintText: "Enter the API base URL",
              ),
              onChanged: (value) {
                AppSettings.baseUrl = value;
                AppSettings.saveSettings();
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              title: const Text("Theme Mode"),
              trailing: PopupMenuButton<ThemeChoice>(
                onSelected: _updateThemeChoice,
                initialValue: _themeChoice,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ThemeChoice.system,
                    child: Text("System"),
                  ),
                  const PopupMenuItem(
                    value: ThemeChoice.light,
                    child: Text("Light"),
                  ),
                  const PopupMenuItem(
                    value: ThemeChoice.dark,
                    child: Text("Dark"),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_themeChoice == ThemeChoice.system
                        ? "System"
                        : _themeChoice == ThemeChoice.light
                            ? "Light"
                            : "Dark"),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
