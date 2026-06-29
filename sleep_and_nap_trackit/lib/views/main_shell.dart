import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/profile.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/reminder_settings_viewmodel.dart';
import 'home_view.dart';
import 'settings_view.dart';
import 'trends_view.dart';

/// Bottom-navigation shell hosting the three primary tabs. An [IndexedStack]
/// keeps each tab's state alive while switching.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  bool _remindersSynced = false;

  static const _tabs = [HomeView(), TrendsView(), SettingsView()];

  void _syncReminders(Profile? profile) {
    if (profile != null && !_remindersSynced) {
      _remindersSynced = true;
      ref.read(reminderSettingsControllerProvider).sync(profile);
    }
  }

  @override
  void initState() {
    super.initState();
    // Handle the case where the profile is already cached when we mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncReminders(ref.read(profileProvider).valueOrNull);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Re-apply the user's reminder/alarm schedule once the profile is loaded,
    // so notifications survive app restarts and device reboots.
    ref.listen(profileProvider, (_, next) => _syncReminders(next.valueOrNull));

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: LullabyColors.surfaceContainer,
        indicatorColor: LullabyColors.primaryContainer.withValues(alpha: 0.3),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: LullabyColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard_rounded, color: LullabyColors.primary),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: LullabyColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
