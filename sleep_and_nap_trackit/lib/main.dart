import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'views/auth_view.dart';
import 'views/home_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Supabase init error: $e');
  }

  runApp(const ProviderScope(child: SleepTrackItApp()));
}

class SleepTrackItApp extends ConsumerWidget {
  const SleepTrackItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleep and Nap TrackIT',
      theme: buildLullabyTheme(),
      home: authState.phase == AuthPhase.authorized
          ? const HomeView()
          : const AuthView(),
    );
  }
}
