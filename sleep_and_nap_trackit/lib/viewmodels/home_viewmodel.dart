import 'package:flutter/material.dart';

import '../core/locator.dart';
import '../models/sleep_log.dart';
import '../services/sleep_service.dart';

class HomeViewModel extends ChangeNotifier {
  final SleepService _sleepService = locator<SleepService>();

  List<SleepLog> _logs = [];
  List<SleepLog> get logs => _logs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    _logs = await _sleepService.getSleepLogs();

    _isLoading = false;
    notifyListeners();
  }

  SleepLog? get latestSleep {
    final sleepLogs = _logs.where((log) => log.type == SleepLogType.sleep);
    return sleepLogs.isEmpty ? null : sleepLogs.first;
  }

  Duration get averageSleepDuration {
    final sleepLogs = _logs.where((log) => log.type == SleepLogType.sleep);
    if (sleepLogs.isEmpty) {
      return Duration.zero;
    }

    final totalMinutes = sleepLogs.fold<int>(
      0,
      (total, log) => total + log.duration.inMinutes,
    );
    return Duration(minutes: totalMinutes ~/ sleepLogs.length);
  }

  int get napCount => _logs.where((log) => log.type == SleepLogType.nap).length;

  int get averageQuality {
    if (_logs.isEmpty) {
      return 0;
    }

    final total = _logs.fold<int>(0, (sum, log) => sum + log.quality);
    return (total / _logs.length).round();
  }
}
