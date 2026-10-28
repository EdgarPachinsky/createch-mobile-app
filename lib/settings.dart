import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme and language, remembered on the device. Armenian and the system theme until the user picks otherwise.
class AppSettings {
  static late SharedPreferences _prefs;
  static final theme = ValueNotifier(ThemeMode.system);
  static final lang = ValueNotifier('hy');

  static Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    theme.value = ThemeMode.values.asNameMap()[_prefs.getString('theme')] ?? ThemeMode.system;
    lang.value = _prefs.getString('lang') ?? 'hy';
  }

  // flips what the user sees now (system dark -> light), and from then on keeps it
  static void toggleTheme(BuildContext context) {
    theme.value = Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    _prefs.setString('theme', theme.value.name);
  }

  static void toggleLang() {
    lang.value = lang.value == 'hy' ? 'en' : 'hy';
    _prefs.setString('lang', lang.value);
  }
}

// Theme and language buttons, on the login screen and in every app bar
class SettingsButtons extends StatelessWidget {
  final Color? color;
  const SettingsButtons({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hy = Localizations.localeOf(context).languageCode == 'hy';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: AppSettings.toggleLang,
          style: TextButton.styleFrom(foregroundColor: color),
          child: Text(hy ? 'EN' : 'ՀԱՅ', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        IconButton(
          tooltip: hy ? (dark ? 'Լուսավոր ռեժիմ' : 'Մութ ռեժիմ') : (dark ? 'Light mode' : 'Dark mode'),
          color: color,
          icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => AppSettings.toggleTheme(context),
        ),
      ],
    );
  }
}
