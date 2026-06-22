import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_and_nap_trackit/core/locator.dart';
import 'package:sleep_and_nap_trackit/main.dart';

void main() {
  setUp(() async {
    await locator.reset();
    setupLocator();
  });

  testWidgets('renders sleep dashboard smoke test', (tester) async {
    await tester.pumpWidget(const SleepTrackItApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sleep and Nap TrackIT'), findsOneWidget);
    expect(find.text('Today\'s rest dashboard'), findsOneWidget);
    expect(find.text('Log Sleep'), findsOneWidget);
    expect(find.text('Log Nap'), findsOneWidget);
  });
}
