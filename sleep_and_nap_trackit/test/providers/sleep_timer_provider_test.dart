import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';
import 'package:sleep_and_nap_trackit/providers/sleep_timer_provider.dart';

void main() {
  group('SleepTimerNotifier', () {
    test('starts in idle status with zero elapsed', () {
      final notifier = SleepTimerNotifier();
      addTearDown(notifier.dispose);

      expect(notifier.state.status, SleepTimerStatus.idle);
      expect(notifier.state.elapsed, Duration.zero);
      expect(notifier.state.startedAt, isNull);
      expect(notifier.state.isActive, isFalse);
    });

    test('start sets running status, type, and a startedAt timestamp', () {
      final notifier = SleepTimerNotifier();
      addTearDown(notifier.dispose);

      notifier.start(SleepLogType.nap);

      expect(notifier.state.status, SleepTimerStatus.running);
      expect(notifier.state.type, SleepLogType.nap);
      expect(notifier.state.startedAt, isNotNull);
      expect(notifier.state.isActive, isTrue);
    });

    test('start is a no-op while already running', () {
      final notifier = SleepTimerNotifier();
      addTearDown(notifier.dispose);

      notifier.start(SleepLogType.sleep);
      final firstStart = notifier.state.startedAt;
      notifier.start(SleepLogType.nap);

      expect(notifier.state.type, SleepLogType.sleep);
      expect(notifier.state.startedAt, firstStart);
    });

    test('stop sets stopped status and captures endedAt >= startedAt', () {
      final notifier = SleepTimerNotifier();
      addTearDown(notifier.dispose);

      notifier.start(SleepLogType.nap);
      notifier.stop();

      expect(notifier.state.status, SleepTimerStatus.stopped);
      expect(notifier.state.endedAt, isNotNull);
      expect(
        notifier.state.endedAt!.isBefore(notifier.state.startedAt!),
        isFalse,
      );
    });

    test('buildLog returns a SleepLog from captured timestamps', () {
      final notifier = SleepTimerNotifier();
      addTearDown(notifier.dispose);

      notifier.start(SleepLogType.sleep);
      notifier.stop();

      final log = notifier.buildLog(userId: 'user-123', quality: 90);

      expect(log.userId, 'user-123');
      expect(log.quality, 90);
      expect(log.type, SleepLogType.sleep);
      expect(log.startedAt, notifier.state.startedAt);
      expect(log.endedAt, notifier.state.endedAt);
    });

    test('reset returns to idle', () {
      final notifier = SleepTimerNotifier();
      addTearDown(notifier.dispose);

      notifier.start(SleepLogType.sleep);
      notifier.stop();
      notifier.reset();

      expect(notifier.state.status, SleepTimerStatus.idle);
      expect(notifier.state.startedAt, isNull);
      expect(notifier.state.endedAt, isNull);
      expect(notifier.state.elapsed, Duration.zero);
    });

    test('stop is a no-op when not running', () {
      final notifier = SleepTimerNotifier();
      addTearDown(notifier.dispose);

      notifier.stop();

      expect(notifier.state.status, SleepTimerStatus.idle);
      expect(notifier.state.endedAt, isNull);
    });
  });
}
