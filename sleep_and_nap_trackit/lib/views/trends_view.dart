import 'package:fl_chart/fl_chart.dart';
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
                const SizedBox(height: 4),
                Text('Hours slept each of the last 7 days', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                SizedBox(height: 170, child: _SleepBarChart(days: stats.last7Days)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Weekly avg', value: _formatDuration(stats.weeklyAverageSleep), color: LullabyColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Monthly avg', value: _formatDuration(stats.monthlyAverageSleep), color: LullabyColors.secondary)),
            ],
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sleep quality', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Average quality score over the last 7 days', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                SizedBox(height: 160, child: _QualityLineChart(trend: stats.qualityTrend)),
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

/// 7-day sleep-duration bars rendered with fl_chart.
class _SleepBarChart extends StatelessWidget {
  const _SleepBarChart({required this.days});

  final List<DailySleep> days;

  @override
  Widget build(BuildContext context) {
    final maxHours = days.fold<double>(0, (m, d) => d.hours > m ? d.hours : m);
    final maxY = (maxHours < 8 ? 8.0 : maxHours.ceilToDouble()) + 1;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => LullabyColors.surfaceContainerHigh,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${rod.toY.toStringAsFixed(1)}h',
              const TextStyle(color: LullabyColors.onSurface, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (_) => const FlLine(color: LullabyColors.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 2,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}h',
                style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(days[i].weekdayLabel, style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].hours,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [LullabyColors.secondaryContainer, LullabyColors.primaryContainer],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 7-day sleep-quality trend line rendered with fl_chart. Days without any
/// session are skipped so the line connects only real data points.
class _QualityLineChart extends StatelessWidget {
  const _QualityLineChart({required this.trend});

  final List<DailyQuality> trend;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < trend.length; i++)
        if (trend[i].quality != null) FlSpot(i.toDouble(), trend[i].quality!.toDouble()),
    ];

    if (spots.isEmpty) {
      return const Center(
        child: Text('No quality data yet', style: TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 13)),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => LullabyColors.surfaceContainerHigh,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toInt()}%',
                      const TextStyle(color: LullabyColors.onSurface, fontWeight: FontWeight.w700, fontSize: 12),
                    ))
                .toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) => const FlLine(color: LullabyColors.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 25,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(trend[i].weekdayLabel, style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 11)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: LullabyColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: LullabyColors.primaryContainer.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
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
