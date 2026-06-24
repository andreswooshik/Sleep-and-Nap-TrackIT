import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      body: SafeArea(
        child: logsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (logs) => _HomeContent(logs: logs),
        ),
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
    final totalMinutes = sleepLogs.fold<int>(
      0,
      (t, l) => t + l.duration.inMinutes,
    );
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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            sliver: SliverToBoxAdapter(
              child: _Header(latestSleep: _latestSleep),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: _SummaryGrid(
                averageSleep: _averageSleepDuration,
                napCount: _napCount,
                averageQuality: _averageQuality,
              ),
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
    final duration = latestSleep == null
        ? '--'
        : _formatDuration(latestSleep!.duration);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF27374D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE6ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
                  color: Color(0xFF27374D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sleep and Nap TrackIT',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Today\'s rest dashboard',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFDDE6ED),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDDE6ED),
                  side: const BorderSide(color: Color(0xFFDDE6ED)),
                  minimumSize: const Size(96, 40),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            duration,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'last overnight sleep',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFDDE6ED),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.averageSleep,
    required this.napCount,
    required this.averageQuality,
  });

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
            _MetricCard(
              icon: Icons.schedule_rounded,
              label: 'Average sleep',
              value: _formatDuration(averageSleep),
              color: const Color(0xFF526D82),
            ),
            _MetricCard(
              icon: Icons.spa_rounded,
              label: 'Naps logged',
              value: '$napCount',
              color: const Color(0xFF7E6B8F),
            ),
            _MetricCard(
              icon: Icons.favorite_rounded,
              label: 'Rest quality',
              value: '$averageQuality%',
              color: const Color(0xFF5B8C6F),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3DED4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 26),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6A7473),
                ),
              ),
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TimerView(type: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _openTimer(context, SleepLogType.sleep),
            icon: const Icon(Icons.nightlight_round),
            label: const Text('Log Sleep'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openTimer(context, SleepLogType.nap),
            icon: const Icon(Icons.airline_seat_individual_suite_rounded),
            label: const Text('Log Nap'),
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
    if (status == SleepTimerStatus.idle) {
      return const SizedBox.shrink();
    }

    final type = ref.watch(sleepTimerProvider.select((s) => s.type));
    final isSleep = type == SleepLogType.sleep;
    final isStopped = status == SleepTimerStatus.stopped;

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF27374D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isSleep
                ? Icons.bedtime_rounded
                : Icons.airline_seat_individual_suite_rounded,
            color: const Color(0xFFDDE6ED),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isSleep ? 'Sleep' : 'Nap'} session ${isStopped ? 'paused' : 'in progress'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const _BannerElapsed(),
              ],
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TimerView(type: type),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF526D82),
              foregroundColor: Colors.white,
            ),
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
      style: const TextStyle(
        color: Color(0xFFDDE6ED),
        fontSize: 13,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
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
        Text(
          'Recent logs',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text('No logs yet'),
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
    final color = isSleep ? const Color(0xFF526D82) : const Color(0xFF7E6B8F);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3DED4)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSleep
                  ? Icons.bedtime_rounded
                  : Icons.airline_seat_individual_suite_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${_formatDuration(log.duration)} | Quality ${log.quality}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6A7473),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA3A2)),
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
