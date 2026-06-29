import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sleep_recommendation.dart';
import '../core/theme.dart';
import '../models/sleep_log.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../providers/home_provider.dart';
import '../providers/sleep_timer_provider.dart';
import 'manual_log_view.dart';
import 'timer_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AmbientGlow(color: LullabyColors.primaryContainer, alignment: Alignment(-0.6, -0.4)),
          AmbientGlow(color: LullabyColors.secondaryContainer, alignment: const Alignment(0.7, 0.8), radius: 250),
          SafeArea(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: LullabyColors.primaryContainer)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: LullabyColors.error))),
              data: (stats) => _HomeContent(stats: stats),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(child: _Header(latestSleep: stats.latestSleep)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: _SummaryGrid(averageSleep: stats.averageSleepDuration, napCount: stats.napCount, averageQuality: stats.averageQuality),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _TodayStatusCard()),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _ActiveSessionBanner()),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverToBoxAdapter(child: _QuickActions()),
        ),
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
          sliver: SliverToBoxAdapter(child: _AddPastLogButton()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          sliver: SliverToBoxAdapter(child: _RecentLogs(logs: stats.logs)),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.latestSleep});

  final SleepLog? latestSleep;

  @override
  Widget build(BuildContext context) {
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

class _AddPastLogButton extends StatelessWidget {
  const _AddPastLogButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ManualLogView()),
        ),
        icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: LullabyColors.primary),
        label: const Text('Add a past log', style: TextStyle(color: LullabyColors.primary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// "Today" tracking-status card: today's logged sleep & naps versus the user's
/// age-based recommended range.
class _TodayStatusCard extends ConsumerWidget {
  const _TodayStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(todayStatusProvider);
    final status = statusAsync.valueOrNull;
    if (status == null) return const SizedBox.shrink();

    final rec = status.recommendation;
    final sleep = status.sleepLoggedToday;
    final sleepLabel = _formatHm(sleep);

    final String headline;
    final Color accent;
    if (rec == null) {
      headline = status.hasLoggedSleep
          ? '$sleepLabel of sleep logged today'
          : 'No sleep logged yet today';
      accent = LullabyColors.primary;
    } else if (!status.hasLoggedSleep) {
      headline = 'Aim for ${rec.sleepRangeLabel} of sleep today';
      accent = LullabyColors.onSurfaceVariant;
    } else {
      headline = rec.statusMessage(sleep);
      switch (rec.comparedTo(sleep)) {
        case RecommendationStatus.below:
          accent = LullabyColors.tertiary;
        case RecommendationStatus.within:
          accent = LullabyColors.primaryContainer;
        case RecommendationStatus.above:
          accent = LullabyColors.secondary;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, color: LullabyColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Today', style: TextStyle(color: LullabyColors.onSurface, fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              if (rec != null)
                Text(
                  'Goal ${rec.sleepRangeLabel}',
                  style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TodayMetric(value: sleepLabel, label: 'Sleep'),
              const SizedBox(width: 24),
              _TodayMetric(value: '${status.napsToday}', label: status.napsToday == 1 ? 'Nap' : 'Naps'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            headline,
            style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
          ),
          if (rec != null && rec.recommendedNapMinutes > 0) ...[
            const SizedBox(height: 6),
            Text(
              rec.napAdvice,
              style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 12, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayMetric extends StatelessWidget {
  const _TodayMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(color: LullabyColors.primary, fontWeight: FontWeight.w900, fontSize: 24)),
        Text(label, style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}

String _formatHm(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
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

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});

  final SleepLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSleep = log.type == SleepLogType.sleep;
    final color = isSleep ? LullabyColors.primary : LullabyColors.secondary;

    final tile = Container(
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

    final id = log.id;
    // Persisted logs can be swiped away; the repository drops them from the
    // local list immediately and mirrors the delete to Supabase.
    if (id == null) return tile;

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ref.read(sleepLogsProvider.notifier).delete(id),
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: LullabyColors.secondary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: LullabyColors.secondary),
      ),
      child: tile,
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
