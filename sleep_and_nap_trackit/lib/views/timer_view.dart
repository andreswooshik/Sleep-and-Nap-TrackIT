import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sleep_log.dart';
import '../providers/home_provider.dart';
import '../providers/service_providers.dart';
import '../providers/sleep_timer_provider.dart';

class TimerView extends ConsumerStatefulWidget {
  const TimerView({super.key, required this.type});

  /// The session type to start when opening a fresh timer. Ignored when a
  /// session is already running (the view then resumes the active session).
  final SleepLogType type;

  @override
  ConsumerState<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends ConsumerState<TimerView> {
  @override
  void initState() {
    super.initState();
    // Start a fresh session only if none is active; otherwise resume.
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF27374D), Color(0xFF1D2B3A)],
          ),
        ),
        child: SafeArea(
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
                        color: Colors.white,
                        tooltip: 'Back to dashboard',
                      ),
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSleep
                            ? Icons.bedtime_rounded
                            : Icons.airline_seat_individual_suite_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title session',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            startedAt == null
                                ? 'Starting...'
                                : 'Started ${_formatClock(startedAt)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
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
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                if (!isStopped) ...[
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _handleStop,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text(
                        'Stop',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _showQualitySheet,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text(
                        'Save Session',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF526D82),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Isolated widget that rebuilds once per second. Scoping the tick here keeps
/// the rest of the timer screen from rebuilding, protecting frame rates.
class _ElapsedDisplay extends ConsumerWidget {
  const _ElapsedDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsed = ref.watch(sleepTimerProvider.select((s) => s.elapsed));

    return Text(
      _formatElapsed(elapsed),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 64,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _QualitySheet extends ConsumerStatefulWidget {
  const _QualitySheet();

  @override
  ConsumerState<_QualitySheet> createState() => _QualitySheetState();
}

class _QualitySheetState extends ConsumerState<_QualitySheet> {
  double _quality = 80;
  bool _saving = false;
  String? _error;

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

    final log = ref
        .read(sleepTimerProvider.notifier)
        .buildLog(userId: userId, quality: _quality.round());

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
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F3EC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How was your rest?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2B2A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Rate the quality of this session',
            style: TextStyle(color: Color(0xFF6A7473), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_quality.round()}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF526D82),
                ),
              ),
              const Text(
                ' / 100',
                style: TextStyle(fontSize: 16, color: Color(0xFF6A7473)),
              ),
            ],
          ),
          Slider(
            value: _quality,
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: const Color(0xFF526D82),
            label: '${_quality.round()}',
            onChanged: _saving ? null : (v) => setState(() => _quality = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _saving ? null : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: Color(0xFF526D82)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF27374D),
                    minimumSize: const Size(0, 48),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
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
