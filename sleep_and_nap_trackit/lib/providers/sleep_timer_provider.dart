import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_log.dart';

enum SleepTimerStatus { idle, running, stopped }

class SleepTimerState {
  const SleepTimerState({
    this.type = SleepLogType.sleep,
    this.startedAt,
    this.endedAt,
    this.elapsed = Duration.zero,
    this.status = SleepTimerStatus.idle,
  });

  final SleepLogType type;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final Duration elapsed;
  final SleepTimerStatus status;

  bool get isActive => status != SleepTimerStatus.idle;

  SleepTimerState copyWith({
    SleepLogType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    Duration? elapsed,
    SleepTimerStatus? status,
  }) {
    return SleepTimerState(
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      elapsed: elapsed ?? this.elapsed,
      status: status ?? this.status,
    );
  }
}

class SleepTimerNotifier extends StateNotifier<SleepTimerState> {
  SleepTimerNotifier() : super(const SleepTimerState());

  Timer? _ticker;

  void start(SleepLogType type) {
    if (state.status == SleepTimerStatus.running) return;

    final now = DateTime.now();
    state = SleepTimerState(
      type: type,
      startedAt: now,
      elapsed: Duration.zero,
      status: SleepTimerStatus.running,
    );

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = state.startedAt;
      if (startedAt == null) return;
      // Wall-clock based: drift-free even if ticks are delayed.
      state = state.copyWith(
        elapsed: DateTime.now().difference(startedAt),
      );
    });
  }

  void stop() {
    if (state.status != SleepTimerStatus.running) return;

    _ticker?.cancel();
    _ticker = null;

    final startedAt = state.startedAt;
    final endedAt = DateTime.now();
    state = state.copyWith(
      endedAt: endedAt,
      elapsed: startedAt == null
          ? state.elapsed
          : endedAt.difference(startedAt),
      status: SleepTimerStatus.stopped,
    );
  }

  void reset() {
    _ticker?.cancel();
    _ticker = null;
    state = const SleepTimerState();
  }

  /// Builds the SleepLog package from the captured timestamps.
  /// Only valid once the timer has been stopped.
  SleepLog buildLog({
    required String userId,
    required int quality,
    List<String> factors = const [],
  }) {
    final startedAt = state.startedAt;
    final endedAt = state.endedAt;
    assert(
      startedAt != null && endedAt != null,
      'buildLog can only be called after the timer has been stopped',
    );
    return SleepLog(
      userId: userId,
      type: state.type,
      startedAt: startedAt!,
      endedAt: endedAt!,
      quality: quality,
      factors: factors,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

/// App-scoped (not autoDispose) so the session keeps running while the user
/// navigates back to the dashboard and can resume it later.
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, SleepTimerState>(
  (ref) => SleepTimerNotifier(),
);
