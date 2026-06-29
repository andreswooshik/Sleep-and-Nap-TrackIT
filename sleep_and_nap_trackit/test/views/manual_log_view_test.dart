import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/models/sleep_log.dart';
import 'package:sleep_and_nap_trackit/views/manual_log_view.dart';

void main() {
  Widget buildApp() => const ProviderScope(
        child: MaterialApp(home: ManualLogView()),
      );

  testWidgets('renders type toggle, both date/time tiles, and Save', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Nap'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
    expect(find.text('Save log'), findsOneWidget);
  });

  testWidgets('defaults to an 8-hour valid window', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    // The default range is start = end - 8h, so the duration label shows 8h.
    expect(find.text('Duration: 8h 0m'), findsOneWidget);
  });

  testWidgets('can switch the session type to Nap', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('Nap'));
    await tester.pump();

    final seg = tester.widget<SegmentedButton<SleepLogType>>(
        find.byType(SegmentedButton<SleepLogType>));
    expect(seg.selected, {SleepLogType.nap});
  });
}
