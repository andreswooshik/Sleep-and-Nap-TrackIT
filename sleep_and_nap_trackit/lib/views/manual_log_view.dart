import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/sleep_quality.dart';
import '../core/theme.dart';
import '../models/sleep_log.dart';
import '../providers/home_provider.dart';

/// Form for logging a past sleep or nap by hand — no live stopwatch required.
/// The user picks a type, a start and end date/time, and a quality rating,
/// then saves a [SleepLog] to the same store the timer uses.
class ManualLogView extends ConsumerStatefulWidget {
  const ManualLogView({super.key});

  @override
  ConsumerState<ManualLogView> createState() => _ManualLogViewState();
}

class _ManualLogViewState extends ConsumerState<ManualLogView> {
  SleepLogType _type = SleepLogType.sleep;
  late DateTime _start;
  late DateTime _end;
  double _quality = 80;
  bool _qualityTouched = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Sensible default: an 8-hour window ending now.
    _end = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    _start = _end.subtract(const Duration(hours: 8));
    _applySuggestedQuality();
  }

  bool get _rangeValid => _end.isAfter(_start);

  Duration get _duration => _end.difference(_start);

  /// The app's computed rating for the current type/duration.
  QualityRating get _rating =>
      rateSleepQuality(type: _type, duration: _duration);

  /// Pre-fills the quality from the app's rating until the user adjusts it.
  void _applySuggestedQuality() {
    if (_qualityTouched || !_rangeValid) return;
    _quality = _rating.score.toDouble();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _editStart() async {
    final picked = await _pickDateTime(_start);
    if (picked != null) {
      setState(() {
        _start = picked;
        _error = null;
        _applySuggestedQuality();
      });
    }
  }

  Future<void> _editEnd() async {
    final picked = await _pickDateTime(_end);
    if (picked != null) {
      setState(() {
        _end = picked;
        _error = null;
        _applySuggestedQuality();
      });
    }
  }

  Future<void> _save() async {
    if (!_rangeValid) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      setState(() => _error = 'You must be signed in to save a session.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final log = SleepLog(
      userId: userId,
      type: _type,
      startedAt: _start,
      endedAt: _end,
      quality: _quality.round(),
    );

    try {
      await ref.read(sleepLogsProvider.notifier).add(log);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save the log. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add past log'),
        backgroundColor: Colors.transparent,
        foregroundColor: LullabyColors.onSurface,
      ),
      body: Stack(
        children: [
          const AmbientGlow(color: LullabyColors.primaryContainer, alignment: Alignment(-0.6, -0.5)),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Text('Session type', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: LullabyColors.primary)),
                const SizedBox(height: 10),
                _TypeToggle(
                  value: _type,
                  onChanged: _saving
                      ? null
                      : (t) => setState(() {
                            _type = t;
                            _applySuggestedQuality();
                          }),
                ),
                const SizedBox(height: 22),
                Text('When', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: LullabyColors.primary)),
                const SizedBox(height: 10),
                _DateTimeTile(
                  label: 'Start',
                  value: _start,
                  icon: Icons.bedtime_rounded,
                  onTap: _saving ? null : _editStart,
                ),
                const SizedBox(height: 10),
                _DateTimeTile(
                  label: 'End',
                  value: _end,
                  icon: Icons.wb_sunny_rounded,
                  onTap: _saving ? null : _editEnd,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _rangeValid ? 'Duration: ${_formatDuration(_duration)}' : 'End must be after start',
                    style: TextStyle(
                      color: _rangeValid ? LullabyColors.onSurfaceVariant : LullabyColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text('Quality', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: LullabyColors.primary)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      labelForScore(_quality.round()),
                      style: const TextStyle(color: LullabyColors.onSurface, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${_quality.round()}',
                      style: const TextStyle(color: LullabyColors.primary, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                Slider(
                  value: _quality,
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: '${_quality.round()}',
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                            _quality = v;
                            _qualityTouched = true;
                          }),
                ),
                if (_rangeValid)
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: LullabyColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _qualityTouched
                              ? 'App rated this ${_rating.score} (${_rating.criteria.first.detail.toLowerCase()})'
                              : 'App-rated from ${_rating.criteria.first.detail.toLowerCase()} — adjust if needed',
                          style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: LullabyColors.error, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: LullabyDecorations.gradientButton(),
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});

  final SleepLogType value;
  final ValueChanged<SleepLogType>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SleepLogType>(
      segments: const [
        ButtonSegment(value: SleepLogType.sleep, label: Text('Sleep'), icon: Icon(Icons.bedtime_rounded)),
        ButtonSegment(value: SleepLogType.nap, label: Text('Nap'), icon: Icon(Icons.airline_seat_individual_suite_rounded)),
      ],
      selected: {value},
      onSelectionChanged: onChanged == null ? null : (s) => onChanged!(s.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: LullabyColors.primaryContainer,
        selectedForegroundColor: LullabyColors.onPrimaryContainer,
        foregroundColor: LullabyColors.onSurface,
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: LullabyDecorations.glassCard(borderRadius: 12),
        child: Row(
          children: [
            Icon(icon, color: LullabyColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: LullabyColors.onSurfaceVariant, fontSize: 14)),
            const Spacer(),
            Text(
              _formatDateTime(value),
              style: const TextStyle(color: LullabyColors.onSurface, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_calendar_rounded, color: LullabyColors.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '${m}m';
  return '${h}h ${m}m';
}

String _formatDateTime(DateTime t) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final period = t.hour < 12 ? 'AM' : 'PM';
  return '${months[t.month - 1]} ${t.day}, $hour:$minute $period';
}
