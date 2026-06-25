import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/sleep_insights.dart';
import '../core/theme.dart';
import '../viewmodels/trends_viewmodel.dart';

class TrendsView extends ConsumerWidget {
  const TrendsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(trendsStatsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const AmbientGlow(color: LullabyColors.primaryContainer, alignment: Alignment(-0.6, -0.5)),
          AmbientGlow(color: LullabyColors.secondaryContainer, alignment: const Alignment(0.8, 0.7), radius: 250),
          SafeArea(
            child: statsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: LullabyColors.primaryContainer)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: LullabyColors.error))),
              data: (stats) => _TrendsContent(stats: stats),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendsContent extends StatelessWidget {
  const _TrendsContent({required this.stats});

  final TrendsStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        Text('Sleep Trends', style: theme.textTheme.headlineMedium?.copyWith(color: LullabyColors.primary)),
        const SizedBox(height: 4),
        Text('Last 7 days summary', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        if (stats.isEmpty)
          const _EmptyState()
        else ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sleep duration', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(height: 160, child: _BarChart(days: stats.last7Days)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Avg. sleep', value: _formatDuration(stats.averageSleep), color: LullabyColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Consistency', value: '${stats.consistency}%', color: LullabyColors.secondary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Avg. quality', value: '${stats.averageQuality}%', color: LullabyColors.tertiary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Naps logged', value: '${stats.napCount}', color: LullabyColors.primary)),
            ],
          ),
          if (stats.topFactors.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Most common factors', style: theme.textTheme.titleMedium?.copyWith(color: LullabyColors.primary)),
            const SizedBox(height: 4),
            Text('What affects your rest most', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: stats.topFactors.take(5).map((fc) {
                  final factor = SleepFactor.fromKey(fc.key);
                  return ListTile(
                    leading: Icon(factor?.icon ?? Icons.help_outline, color: LullabyColors.primary, size: 20),
                    title: Text(factor?.label ?? fc.key, style: const TextStyle(color: LullabyColors.onSurface, fontSize: 14)),
                    trailing: Text(
                      '${fc.count}×',
                      style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontWeight: FontWeight.w700),
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.days});

  final List<DailySleep> days;

  @override
  Widget build(BuildContext context) {
    final maxHours = days.fold<double>(0, (m, d) => d.hours > m ? d.hours : m);
    final scaleMax = maxHours < 8 ? 8.0 : maxHours.ceilToDouble();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: days.map((day) {
        final fraction = scaleMax == 0 ? 0.0 : (day.hours / scaleMax).clamp(0.0, 1.0);
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                day.hours == 0 ? '' : day.hours.toStringAsFixed(1),
                style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 10),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: fraction == 0 ? 0.02 : fraction,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [LullabyColors.secondaryContainer, LullabyColors.primaryContainer],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(day.weekdayLabel, style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 11)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: LullabyDecorations.glassCard(borderRadius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 11, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.bedtime_outlined, size: 56, color: LullabyColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No sessions yet', style: TextStyle(color: LullabyColors.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Log a sleep or nap to see your trends.', style: TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 13)),
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
