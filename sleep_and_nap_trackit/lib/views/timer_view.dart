import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/sleep_insights.dart';
import '../core/theme.dart';
import '../models/sleep_log.dart';
import '../providers/home_provider.dart';
import '../providers/service_providers.dart';
import '../providers/sleep_timer_provider.dart';

class TimerView extends ConsumerStatefulWidget {
  const TimerView({super.key, required this.type});

  final SleepLogType type;

  @override
  ConsumerState<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends ConsumerState<TimerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(sleepTimerProvider.notifier);
      if (ref.read(sleepTimerProvider).status == SleepTimerStatus.idle) {
        notifier.start(widget.type);
      }
    });
  }

  Future<void> _handleStop() async {
    ref.read(sleepTimerProvider.notifier).stop();
    await _showQualitySheet();
  }

  Future<void> _showQualitySheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _QualitySheet(),
    );

    if (saved == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleDiscard() {
    ref.read(sleepTimerProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(sleepTimerProvider.select((s) => s.status));
    final type = ref.watch(sleepTimerProvider.select((s) => s.type));
    final startedAt = ref.watch(sleepTimerProvider.select((s) => s.startedAt));
    final isSleep = type == SleepLogType.sleep;
    final title = isSleep ? 'Sleep' : 'Nap';
    final isStopped = status == SleepTimerStatus.stopped;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [LullabyColors.surface, LullabyColors.surfaceContainerLow],
              ),
            ),
          ),
          const AmbientGlow(color: LullabyColors.primaryContainer, alignment: Alignment(-0.5, -0.3), radius: 400),
          AmbientGlow(color: LullabyColors.secondaryContainer, alignment: const Alignment(0.5, 0.7), radius: 300),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (!isStopped)
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: LullabyColors.onSurface,
                          tooltip: 'Back to dashboard',
                        ),
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: LullabyColors.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSleep ? Icons.bedtime_rounded : Icons.airline_seat_individual_suite_rounded,
                          color: LullabyColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title session',
                              style: const TextStyle(color: LullabyColors.onSurface, fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            Text(
                              startedAt == null ? 'Starting...' : 'Started ${_formatClock(startedAt)}',
                              style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Center(child: _ElapsedDisplay()),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      isStopped ? 'Session stopped' : 'Recording...',
                      style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                  const Spacer(),
                  if (!isStopped) ...[
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: _handleStop,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Stop', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: LullabyColors.error,
                          foregroundColor: LullabyColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.dashboard_rounded, size: 18),
                        label: const Text('Keep running, go to dashboard'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LullabyColors.onSurface,
                          side: const BorderSide(color: LullabyColors.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      height: 56,
                      child: DecoratedBox(
                        decoration: LullabyDecorations.gradientButton(),
                        child: FilledButton.icon(
                          onPressed: _showQualitySheet,
                          icon: const Icon(Icons.check_rounded, color: Colors.white),
                          label: const Text('Save Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _handleDiscard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: LullabyColors.onSurface,
                          side: const BorderSide(color: LullabyColors.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Discard'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElapsedDisplay extends ConsumerWidget {
  const _ElapsedDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(sleepTimerProvider.select((s) => s.elapsed));

    return Text(
      _formatElapsed(elapsed),
      style: TextStyle(
        color: LullabyColors.primary,
        fontSize: 72,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        shadows: [
          Shadow(color: LullabyColors.primaryContainer.withValues(alpha: 0.4), blurRadius: 30),
        ],
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

enum _ReflectStep { quality, factors, tips }

class _QualitySheet extends ConsumerStatefulWidget {
  const _QualitySheet();

  @override
  ConsumerState<_QualitySheet> createState() => _QualitySheetState();
}

class _QualitySheetState extends ConsumerState<_QualitySheet> {
  _ReflectStep _step = _ReflectStep.quality;
  double _quality = 80;
  final Set<SleepFactor> _factors = {};
  bool _saving = false;
  String? _error;

  bool get _isPoor => _quality.round() < kGoodQualityThreshold;

  ({String emoji, String label}) get _qualityMood {
    final q = _quality.round();
    if (q >= 80) return (emoji: '😄', label: 'Great');
    if (q >= 60) return (emoji: '🙂', label: 'Good');
    if (q >= 40) return (emoji: '😐', label: 'Okay');
    if (q >= 20) return (emoji: '😟', label: 'Restless');
    return (emoji: '😴', label: 'Poor');
  }

  void _onPrimary() {
    switch (_step) {
      case _ReflectStep.quality:
        if (_isPoor) {
          setState(() => _step = _ReflectStep.factors);
        } else {
          _save();
        }
      case _ReflectStep.factors:
        setState(() => _step = _ReflectStep.tips);
      case _ReflectStep.tips:
        _save();
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _saving = false;
        _error = 'You must be signed in to save a session.';
      });
      return;
    }

    final log = ref.read(sleepTimerProvider.notifier).buildLog(
          userId: userId,
          quality: _quality.round(),
          factors: _factors.map((f) => f.key).toList(),
        );

    try {
      await ref.read(sleepServiceProvider).addSleepLog(log);
      ref.read(sleepTimerProvider.notifier).reset();
      ref.invalidate(sleepLogsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not save session. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: LullabyColors.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (_step) {
              _ReflectStep.quality => _buildQualityStep(),
              _ReflectStep.factors => _buildFactorsStep(),
              _ReflectStep.tips => _buildTipsStep(),
            },
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: LullabyColors.error, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityStep() {
    final mood = _qualityMood;
    return Column(
      key: const ValueKey(_ReflectStep.quality),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('How was your rest?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LullabyColors.onSurface)),
        const SizedBox(height: 4),
        const Text('Rate the quality of this session', style: TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Text(mood.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 4),
              Text(
                '${_quality.round()}  ·  ${mood.label}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LullabyColors.primary),
              ),
            ],
          ),
        ),
        Slider(
          value: _quality,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${_quality.round()}',
          onChanged: _saving ? null : (v) => setState(() => _quality = v),
        ),
      ],
    );
  }

  Widget _buildFactorsStep() {
    return Column(
      key: const ValueKey(_ReflectStep.factors),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What affected your rest?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LullabyColors.onSurface)),
        const SizedBox(height: 4),
        const Text('Pick anything that applies — optional', style: TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SleepFactor.values.map((f) {
            final selected = _factors.contains(f);
            return FilterChip(
              avatar: Icon(f.icon, size: 18, color: selected ? LullabyColors.onPrimaryContainer : LullabyColors.primary),
              label: Text(f.label),
              selected: selected,
              showCheckmark: false,
              backgroundColor: LullabyColors.surfaceContainerHigh,
              selectedColor: LullabyColors.primaryContainer,
              labelStyle: TextStyle(
                color: selected ? LullabyColors.onPrimaryContainer : LullabyColors.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              side: BorderSide(color: selected ? Colors.transparent : LullabyColors.outlineVariant),
              onSelected: _saving
                  ? null
                  : (v) => setState(() => v ? _factors.add(f) : _factors.remove(f)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTipsStep() {
    final tips = tipsForFactors(_factors);
    return Column(
      key: const ValueKey(_ReflectStep.tips),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tips to improve', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: LullabyColors.onSurface)),
        const SizedBox(height: 4),
        const Text('Small changes for a better next session', style: TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 13)),
        const SizedBox(height: 16),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LullabyColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LullabyColors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: LullabyColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip, style: const TextStyle(color: LullabyColors.onSurface, fontSize: 13, height: 1.3))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final isFirst = _step == _ReflectStep.quality;
    final primaryLabel = switch (_step) {
      _ReflectStep.quality => _isPoor ? 'Next' : 'Save',
      _ReflectStep.factors => 'See tips',
      _ReflectStep.tips => 'Save',
    };

    void onSecondary() {
      if (isFirst) {
        Navigator.of(context).pop(false);
      } else {
        setState(() {
          _step = _step == _ReflectStep.tips ? _ReflectStep.factors : _ReflectStep.quality;
        });
      }
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : onSecondary,
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(isFirst ? 'Cancel' : 'Back'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DecoratedBox(
            decoration: LullabyDecorations.gradientButton(),
            child: FilledButton(
              onPressed: _saving ? null : _onPrimary,
              style: FilledButton.styleFrom(backgroundColor: Colors.transparent, minimumSize: const Size(0, 48)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(primaryLabel, style: const TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatElapsed(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _formatClock(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
