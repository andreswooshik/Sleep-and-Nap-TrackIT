import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/providers/service_providers.dart';
import 'package:sleep_and_nap_trackit/services/profile_service.dart';
import 'package:sleep_and_nap_trackit/services/sleep_service.dart';
import 'package:sleep_and_nap_trackit/views/home_view.dart';
import 'package:sleep_and_nap_trackit/views/manual_log_view.dart';

void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        sleepServiceProvider.overrideWithValue(MockSleepService()),
        profileServiceProvider.overrideWithValue(MockProfileService()),
      ],
      child: const MaterialApp(home: HomeView()),
    );
  }

  // A tall viewport so the dashboard's lazily-built slivers (including the
  // "Add a past log" action below the fold) are all laid out and findable.
  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
  }

  testWidgets('renders the tracking buttons and the Today status card', (tester) async {
    await pumpDashboard(tester);

    expect(find.text('Log Sleep'), findsOneWidget);
    expect(find.text('Log Nap'), findsOneWidget);
    expect(find.text('Add a past log'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('"Add a past log" opens the manual entry form', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Add a past log'));
    await tester.pumpAndSettle();

    expect(find.byType(ManualLogView), findsOneWidget);
    expect(find.text('Save log'), findsOneWidget);
  });

  testWidgets('the manual form exposes the date/time inputs and type toggle', (tester) async {
    await pumpDashboard(tester);

    await tester.tap(find.text('Add a past log'));
    await tester.pumpAndSettle();

    expect(find.text('Start'), findsOneWidget);
    expect(find.text('End'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget); // quality input
    expect(find.text('Sleep'), findsOneWidget); // type toggle segment
    expect(find.text('Nap'), findsOneWidget);
  });
}
