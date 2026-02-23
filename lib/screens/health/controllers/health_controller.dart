import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class PeriodLog {
  DateTime date;
  bool isIgnored;

  PeriodLog({required this.date, this.isIgnored = false});

  factory PeriodLog.fromJson(Map<String, dynamic> json) => PeriodLog(
    date: DateTime.parse(json['date']),
    isIgnored: json['isIgnored'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'isIgnored': isIgnored,
  };
}

class HealthController extends GetxController {
  final storage = GetStorage();

  var logs = <PeriodLog>[].obs;
  var averageCycleLength = 28.obs;
  var predictedNextPeriod = DateTime.now().obs;
  var periodDuration = 5.obs;

  @override
  void onInit() {
    super.onInit();
    var storedLogs = storage.read<List>('period_logs');
    if (storedLogs != null) {
      logs.assignAll(storedLogs.map((e) => PeriodLog.fromJson(e)).toList());
    }
    _calculatestats();

    ever(logs, (_) {
      storage.write('period_logs', logs.map((e) => e.toJson()).toList());
      _calculatestats();
    });
  }

  // --- ACTIONS ---

  bool checkIsOutlier(DateTime newDate) {
    if (logs.isEmpty) return false;
    final lastDate = logs.first.date;
    final diff = newDate.difference(lastDate).inDays.abs();
    // Warn if cycle is < 21 days or > 35 days
    if (diff < 21 || diff > 35) return true;
    return false;
  }

  void logPeriod(DateTime date, {bool ignoreForPrediction = false}) {
    if (logs.any((log) => _isSameDay(log.date, date))) return;
    logs.add(PeriodLog(date: date, isIgnored: ignoreForPrediction));
    logs.sort((a, b) => b.date.compareTo(a.date));
  }

  void deleteLog(DateTime date) {
    logs.removeWhere((log) => _isSameDay(log.date, date));
  }

  // --- SMART MATH ---

  void _calculatestats() {
    if (logs.length < 2) {
      predictedNextPeriod.value = logs.isNotEmpty
          ? logs.first.date.add(const Duration(days: 28))
          : DateTime.now();
      return;
    }

    List<int> cycleLengths = [];
    for (int i = 0; i < logs.length - 1; i++) {
      if (logs[i].isIgnored) continue;
      final gap = logs[i].date.difference(logs[i + 1].date).inDays;
      if (gap > 15 && gap < 60) cycleLengths.add(gap);
    }

    if (cycleLengths.isEmpty) {
      averageCycleLength.value = 28;
    } else {
      double weightedSum = 0;
      double totalWeight = 0;

      for (int i = 0; i < cycleLengths.length; i++) {
        double weight = 1.0;
        if (i == 0)
          weight = 0.5;
        else if (i == 1)
          weight = 0.3;
        else
          weight = 0.2;

        weightedSum += cycleLengths[i] * weight;
        totalWeight += weight;
      }
      averageCycleLength.value = (weightedSum / totalWeight).round();
    }

    if (logs.isNotEmpty) {
      predictedNextPeriod.value = logs.first.date.add(
        Duration(days: averageCycleLength.value),
      );
    }
  }

  // --- HELPERS ---

  // Is this date a confirmed period day?
  bool isPeriodDay(DateTime date) {
    for (var log in logs) {
      final diff = date.difference(log.date).inDays;
      if (diff >= 0 && diff < periodDuration.value) return true;
    }
    return false;
  }

  // Is this date a predicted future period day?
  bool isPredictedPeriodDay(DateTime date) {
    if (logs.isEmpty) return false;
    // Simple prediction for next month only
    final diff = date.difference(predictedNextPeriod.value).inDays;
    return diff >= 0 && diff < periodDuration.value;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
