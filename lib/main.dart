import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'kids_screen.dart';
import 'login_screen.dart';
import 'settings.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  // values come from env.json: flutter run --dart-define-from-file=env.json
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  runApp(const CreatechApp());
}

class CreatechApp extends StatelessWidget {
  const CreatechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppSettings.theme, AppSettings.lang]),
      builder: (context, _) => MaterialApp(
        title: 'Createch',
        debugShowCheckedModeBanner: false,
        theme: appTheme(Brightness.light),
        darkTheme: appTheme(Brightness.dark),
        themeMode: AppSettings.theme.value,
        locale: Locale(AppSettings.lang.value),
        supportedLocales: const [Locale('hy'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        // the stored session survives restarts, so a signed-in account goes straight in
        home: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, _) =>
              Supabase.instance.client.auth.currentSession == null ? const LoginScreen() : const KidsScreen(),
        ),
      ),
    );
  }
}
