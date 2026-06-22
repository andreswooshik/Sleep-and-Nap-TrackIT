import 'package:flutter/material.dart';

import 'core/locator.dart';
import 'views/home_view.dart';

void main() {
  setupLocator();
  runApp(const SleepTrackItApp());
}

class SleepTrackItApp extends StatelessWidget {
  const SleepTrackItApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF526D82);

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
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xFF1D2B2A),
          displayColor: const Color(0xFF1D2B2A),
        ),
      ),
      home: const HomeView(),
    );
  }
}
