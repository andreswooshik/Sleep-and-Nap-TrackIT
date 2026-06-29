import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/services/profile_service.dart';
import 'package:sleep_and_nap_trackit/services/reminder_service.dart';
import 'package:sleep_and_nap_trackit/views/timer_view.dart';

void main() {
  Widget buildApp(SleepLogType type) {
    return ProviderScope(
      overrides: [
        // The timer now schedules/cancels alarms and reads the profile for the
        // app quality rating — give it inert, test-safe dependencies.
        reminderServiceProvider.overrideWithValue(const NoopReminderService()),
        profileServiceProvider.overrideWithValue(MockProfileService()),
      ],
      child: MaterialApp(home: TimerView(type: type)),
    );
  }

  testWidgets('renders the session type and starting elapsed', (tester) async {
    await tester.pumpWidget(buildApp(SleepLogType.sleep));
    await tester.pump();

    expect(find.text('Sleep session'), findsOneWidget);
    expect(find.text('00:00:00'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('nap session shows nap title', (tester) async {
    await tester.pumpWidget(buildApp(SleepLogType.nap));
    await tester.pump();

    expect(find.text('Nap session'), findsOneWidget);
  });

  testWidgets('tapping Stop reveals the quality sheet', (tester) async {
    await tester.pumpWidget(buildApp(SleepLogType.sleep));
    await tester.pump();

    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();

    expect(find.text('How was your rest?'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    // The quality sheet is open: the Cancel (secondary) action is always shown
    // on the first step regardless of the app-rated score.
    expect(find.text('Cancel'), findsOneWidget);
  });
}
