import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents the three possible theme choices in the app.
enum ThemeChoice { system, light, dark }

/// Manages persistent settings (base URL and theme mode) using SharedPreferences.
class AppSettings {
  static const String _keyBaseUrl = 'base_url';
  static const String _keyThemeMode = 'theme_mode';

  /// The base URL for API requests. Defaults to 'https://example.com'.
  static String baseUrl = 'https://example.com';

  /// ValueNotifier that holds the current [ThemeMode].
  /// Listeners (e.g., MaterialApp) can rebuild when this value changes.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  /// Convenience getter for the current [ThemeMode].
  static ThemeMode get themeMode => themeModeNotifier.value;

  /// Convenience setter: updates the notifier’s value.
  static set themeMode(ThemeMode value) {
    themeModeNotifier.value = value;
  }

  /// Loads stored settings from SharedPreferences into memory.
  /// - Reads the stored base URL (if any).
  /// - Reads the stored theme string and updates [themeModeNotifier].
  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    baseUrl = prefs.getString(_keyBaseUrl) ?? 'https://example.com';

    final storedTheme = prefs.getString(_keyThemeMode) ?? 'system';
    switch (storedTheme) {
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

  /// Persists the current settings (base URL and theme mode) to SharedPreferences.
  static Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, baseUrl);

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

    await prefs.setString(_keyThemeMode, themeString);
  }
}

/// A page that allows the user to update the API base URL and choose a theme mode.
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _baseUrlController;
  late ThemeChoice _themeChoice;

  @override
  void initState() {
    super.initState();

    // Initialize the text field with the current base URL.
    _baseUrlController = TextEditingController(text: AppSettings.baseUrl);

    // Determine the initial ThemeChoice based on AppSettings.themeMode.
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

  /// Called when the user selects a new theme choice from the popup menu.
  void _updateThemeChoice(ThemeChoice choice) {
    setState(() {
      _themeChoice = choice;
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
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Base URL text field
            TextField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                hintText: 'Enter the API base URL',
              ),
              onChanged: (value) {
                AppSettings.baseUrl = value;
                AppSettings.saveSettings();
              },
            ),
            const SizedBox(height: 24),

            // Theme mode selector
            ListTile(
              title: const Text('Theme Mode'),
              trailing: PopupMenuButton<ThemeChoice>(
                onSelected: _updateThemeChoice,
                initialValue: _themeChoice,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ThemeChoice.system,
                    child: Text('System'),
                  ),
                  PopupMenuItem(
                    value: ThemeChoice.light,
                    child: Text('Light'),
                  ),
                  PopupMenuItem(
                    value: ThemeChoice.dark,
                    child: Text('Dark'),
                  ),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // Show the current choice as text
                      _themeChoice == ThemeChoice.system
                          ? 'System'
                          : _themeChoice == ThemeChoice.light
                              ? 'Light'
                              : 'Dark',
                    ),
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
