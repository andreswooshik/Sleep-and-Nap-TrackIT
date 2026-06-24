import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sleep_log.dart';
import 'service_providers.dart';

final sleepLogsProvider = FutureProvider<List<SleepLog>>((ref) async {
  final service = ref.watch(sleepServiceProvider);
  return service.getSleepLogs();
});
