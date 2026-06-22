import 'package:flutter/material.dart';
import '../core/locator.dart';
import '../services/sleep_service.dart';

class HomeViewModel extends ChangeNotifier {
  final SleepService _sleepService = locator<SleepService>();
  
  List<String> _logs = [];
  List<String> get logs => _logs;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners(); // Tell the UI to rebuild (show loading spinner)

    _logs = await _sleepService.getSleepLogs();

    _isLoading = false;
    notifyListeners(); // Tell the UI to rebuild (show data)
  }
}