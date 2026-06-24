import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/locator.dart';
import 'core/supabase_config.dart';
import 'services/auth_service.dart';
import 'views/auth_view.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  setupLocator();
  runApp(const SleepTrackItApp());
}

class SleepTrackItApp extends StatelessWidget {
  const SleepTrackItApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF526D82);
    final authService = locator<AuthService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleep and Nap TrackIT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F3EC),
        useMaterial3: true,
      ),
      home: authService.isAuthenticated ? const HomeView() : const AuthView(),
    );
  }
}
