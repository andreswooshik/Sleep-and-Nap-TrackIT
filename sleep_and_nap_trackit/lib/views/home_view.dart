import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../models/sleep_log.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../providers/sleep_timer_provider.dart';
import 'timer_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(sleepLogsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AmbientGlow(color: LullabyColors.primaryContainer, alignment: Alignment(-0.6, -0.4)),
          AmbientGlow(color: LullabyColors.secondaryContainer, alignment: const Alignment(0.7, 0.8), radius: 250),
          SafeArea(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: LullabyColors.primaryContainer)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: LullabyColors.error))),
              data: (logs) => _HomeContent(logs: logs),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.logs});

  final List<SleepLog> logs;

  SleepLog? get _latestSleep {
    final sleepLogs = logs.where((log) => log.type == SleepLogType.sleep);
    return sleepLogs.isEmpty ? null : sleepLogs.first;
  }

  Duration get _averageSleepDuration {
    final sleepLogs = logs.where((log) => log.type == SleepLogType.sleep);
    if (sleepLogs.isEmpty) return Duration.zero;
    final totalMinutes = sleepLogs.fold<int>(0, (t, l) => t + l.duration.inMinutes);
    return Duration(minutes: totalMinutes ~/ sleepLogs.length);
  }

  int get _napCount => logs.where((log) => log.type == SleepLogType.nap).length;

  int get _averageQuality {
    if (logs.isEmpty) return 0;
    final total = logs.fold<int>(0, (sum, log) => sum + log.quality);
    return (total / logs.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {},
      color: LullabyColors.primaryContainer,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(child: _Header(latestSleep: _latestSleep)),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _SummaryGrid(averageSleep: _averageSleepDuration, napCount: _napCount, averageQuality: _averageQuality),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
            sliver: SliverToBoxAdapter(child: _ActiveSessionBanner()),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
            sliver: SliverToBoxAdapter(child: _QuickActions()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            sliver: SliverToBoxAdapter(child: _RecentLogs(logs: logs)),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.latestSleep});

  final SleepLog? latestSleep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final duration = latestSleep == null ? '--' : _formatDuration(latestSleep!.duration);

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: LullabyColors.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bedtime_rounded, color: LullabyColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sleep and Nap TrackIT', style: theme.textTheme.titleLarge?.copyWith(color: LullabyColors.primary)),
                    Text('Today\'s rest dashboard', style: theme.textTheme.bodyMedium?.copyWith(color: LullabyColors.onSurfaceVariant)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: LullabyColors.primary,
                  side: const BorderSide(color: LullabyColors.outlineVariant),
                  minimumSize: const Size(96, 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(duration, style: theme.textTheme.displaySmall?.copyWith(color: LullabyColors.primary)),
          const SizedBox(height: 6),
          Text('last overnight sleep', style: theme.textTheme.bodyLarge?.copyWith(color: LullabyColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.averageSleep, required this.napCount, required this.averageQuality});

  final Duration averageSleep;
  final int napCount;
  final int averageQuality;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        return GridView.count(
          crossAxisCount: isWide ? 3 : 2,
          childAspectRatio: isWide ? 1.55 : 1.25,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(icon: Icons.schedule_rounded, label: 'Average sleep', value: _formatDuration(averageSleep), color: LullabyColors.primary),
            _MetricCard(icon: Icons.spa_rounded, label: 'Naps logged', value: '$napCount', color: LullabyColors.secondary),
            _MetricCard(icon: Icons.favorite_rounded, label: 'Rest quality', value: '$averageQuality%', color: LullabyColors.tertiary),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LullabyDecorations.glassCard(borderRadius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: LullabyColors.onSurface)),
              ),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: LullabyColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  void _openTimer(BuildContext context, SleepLogType type) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TimerView(type: type)));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: DecoratedBox(
              decoration: LullabyDecorations.gradientButton(),
              child: FilledButton.icon(
                onPressed: () => _openTimer(context, SleepLogType.sleep),
                icon: const Icon(Icons.nightlight_round, color: Colors.white),
                label: const Text('Log Sleep', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _openTimer(context, SleepLogType.nap),
              icon: const Icon(Icons.airline_seat_individual_suite_rounded),
              label: const Text('Log Nap'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveSessionBanner extends ConsumerWidget {
  const _ActiveSessionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(sleepTimerProvider.select((s) => s.status));
    if (status == SleepTimerStatus.idle) return const SizedBox.shrink();

    final type = ref.watch(sleepTimerProvider.select((s) => s.type));
    final isSleep = type == SleepLogType.sleep;
    final isStopped = status == SleepTimerStatus.stopped;

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(14),
      decoration: LullabyDecorations.glassCard(borderRadius: 12),
      child: Row(
        children: [
          Icon(
            isSleep ? Icons.bedtime_rounded : Icons.airline_seat_individual_suite_rounded,
            color: LullabyColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isSleep ? 'Sleep' : 'Nap'} session ${isStopped ? 'paused' : 'in progress'}',
                  style: const TextStyle(color: LullabyColors.onSurface, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const _BannerElapsed(),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TimerView(type: type))),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}

class _BannerElapsed extends ConsumerWidget {
  const _BannerElapsed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(sleepTimerProvider.select((s) => s.elapsed));
    final h = elapsed.inHours.toString().padLeft(2, '0');
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text(
      '$h:$m:$s',
      style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()]),
    );
  }
}

class _RecentLogs extends StatelessWidget {
  const _RecentLogs({required this.logs});

  final List<SleepLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent logs', style: theme.textTheme.titleMedium?.copyWith(color: LullabyColors.primary)),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text('No logs yet', style: TextStyle(color: LullabyColors.onSurfaceVariant)),
            ),
          )
        else
          ...logs.map((log) => _LogTile(log: log)),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final SleepLog log;

  @override
  Widget build(BuildContext context) {
    final isSleep = log.type == SleepLogType.sleep;
    final color = isSleep ? LullabyColors.primary : LullabyColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: LullabyDecorations.glassCard(borderRadius: 12),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSleep ? Icons.bedtime_rounded : Icons.airline_seat_individual_suite_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: LullabyColors.onSurface)),
                Text(
                  '${_formatDuration(log.duration)} | Quality ${log.quality}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LullabyColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: LullabyColors.outline),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  if (duration == Duration.zero) return '--';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}
