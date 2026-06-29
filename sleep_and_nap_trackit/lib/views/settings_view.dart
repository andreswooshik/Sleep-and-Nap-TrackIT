import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/reminder_schedule.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../viewmodels/reminder_settings_viewmodel.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final email = ref.watch(authServiceProvider).currentUserEmail ?? '';

    return Scaffold(
      body: Stack(
        children: [
          const AmbientGlow(color: LullabyColors.primaryContainer, alignment: Alignment(0.7, -0.6)),
          SafeArea(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: LullabyColors.primaryContainer)),
              error: (e, _) => _SettingsList(profile: null, email: email),
              data: (profile) => _SettingsList(profile: profile, email: email),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsList extends ConsumerWidget {
  const _SettingsList({required this.profile, required this.email});

  final Profile? profile;
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text('Profile', style: theme.textTheme.headlineMedium?.copyWith(color: LullabyColors.primary)),
        const SizedBox(height: 20),

        // --- Profile hero ---
        GlassCard(
          child: Column(
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: LullabyColors.primaryContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: LullabyColors.primary, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                profile?.fullName ?? 'Sleeper',
                style: theme.textTheme.titleLarge?.copyWith(color: LullabyColors.onSurface),
              ),
              const SizedBox(height: 4),
              Text(email, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (profile != null) ...[
          Text('Preferences', style: theme.textTheme.titleMedium?.copyWith(color: LullabyColors.primary)),
          const SizedBox(height: 12),
          _SleepGoalTile(profile: profile!),
          const SizedBox(height: 10),
          _NapHabitTile(profile: profile!),
          const SizedBox(height: 24),

          Text('Reminders & alarm', style: theme.textTheme.titleMedium?.copyWith(color: LullabyColors.primary)),
          const SizedBox(height: 12),
          _NotificationsTile(profile: profile!),
          if (profile!.notificationsEnabled) ...[
            const SizedBox(height: 10),
            _BedtimeReminderTile(profile: profile!),
            const SizedBox(height: 10),
            _WakeAlarmTile(profile: profile!),
          ],
          const SizedBox(height: 24),
        ],

        // --- Logout ---
        OutlinedButton.icon(
          onPressed: () => ref.read(authProvider.notifier).signOut(),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            foregroundColor: LullabyColors.error,
            side: BorderSide(color: LullabyColors.error.withValues(alpha: 0.4)),
            minimumSize: const Size(0, 52),
          ),
        ),
      ],
    );
  }
}

class _SleepGoalTile extends ConsumerWidget {
  const _SleepGoalTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PrefShell(
      icon: Icons.bedtime_rounded,
      iconColor: LullabyColors.primary,
      title: 'Sleep goal',
      subtitle: 'Nightly target',
      trailing: DropdownButton<int>(
        value: profile.sleepGoalHours,
        dropdownColor: LullabyColors.surfaceContainerHigh,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: LullabyColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
        items: List.generate(5, (i) {
          final h = i + 6;
          return DropdownMenuItem(value: h, child: Text('${h}h'));
        }),
        onChanged: (v) {
          if (v != null) {
            ref.read(profileControllerProvider).update(profile.copyWith(sleepGoalHours: v));
          }
        },
      ),
    );
  }
}

class _NapHabitTile extends ConsumerWidget {
  const _NapHabitTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PrefShell(
      icon: Icons.airline_seat_individual_suite_rounded,
      iconColor: LullabyColors.secondary,
      title: 'Nap habit',
      subtitle: 'How often you nap',
      trailing: DropdownButton<String>(
        value: profile.napHabit,
        dropdownColor: LullabyColors.surfaceContainerHigh,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: LullabyColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
        items: const [
          DropdownMenuItem(value: 'Never', child: Text('Never')),
          DropdownMenuItem(value: 'Sometimes', child: Text('Sometimes')),
          DropdownMenuItem(value: 'Daily', child: Text('Daily')),
        ],
        onChanged: (v) {
          if (v != null) {
            ref.read(profileControllerProvider).update(profile.copyWith(napHabit: v));
          }
        },
      ),
    );
  }
}

class _NotificationsTile extends ConsumerWidget {
  const _NotificationsTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _PrefShell(
      icon: Icons.notifications_rounded,
      iconColor: LullabyColors.tertiary,
      title: 'Reminders & alarm',
      subtitle: 'Bedtime reminder and wake-up alarm',
      trailing: Switch.adaptive(
        value: profile.notificationsEnabled,
        activeTrackColor: LullabyColors.primaryContainer,
        onChanged: (v) {
          ref.read(reminderSettingsControllerProvider).setEnabled(profile, v);
        },
      ),
    );
  }
}

class _BedtimeReminderTile extends ConsumerWidget {
  const _BedtimeReminderTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ClockTime.tryParse(profile.usualBedtime) ?? const ClockTime(22, 0);
    return _PrefShell(
      icon: Icons.bedtime_outlined,
      iconColor: LullabyColors.primary,
      title: 'Bedtime reminder',
      subtitle: 'Nudge to log your sleep',
      trailing: _TimeButton(
        time: time,
        onPicked: (picked) =>
            ref.read(reminderSettingsControllerProvider).setBedtime(profile, picked),
      ),
    );
  }
}

class _WakeAlarmTile extends ConsumerWidget {
  const _WakeAlarmTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = ClockTime.tryParse(profile.usualWakeUpTime) ?? const ClockTime(7, 0);
    return _PrefShell(
      icon: Icons.alarm_rounded,
      iconColor: LullabyColors.secondary,
      title: 'Wake-up alarm',
      subtitle: 'Daily alarm time',
      trailing: _TimeButton(
        time: time,
        onPicked: (picked) =>
            ref.read(reminderSettingsControllerProvider).setWakeTime(profile, picked),
      ),
    );
  }
}

/// A pill button showing a [ClockTime] that opens the time picker on tap.
class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.time, required this.onPicked});

  final ClockTime time;
  final ValueChanged<ClockTime> onPicked;

  String get _label {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: time.hour, minute: time.minute),
    );
    if (picked != null) onPicked(ClockTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _pick(context),
      icon: const Icon(Icons.schedule_rounded, size: 16, color: LullabyColors.primary),
      label: Text(_label, style: const TextStyle(color: LullabyColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }
}

class _PrefShell extends StatelessWidget {
  const _PrefShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: LullabyDecorations.glassCard(borderRadius: 12),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: LullabyColors.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
