import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class PeriodLog {
  DateTime date;
  bool isIgnored;

  PeriodLog({required this.date, this.isIgnored = false});

  factory PeriodLog.fromJson(Map<String, dynamic> json) {
    return PeriodLog(
      date: DateTime.parse(json['date']),
      isIgnored: json['isIgnored'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'isIgnored': isIgnored};
  }
}

class HealthController extends GetxController {
  final storage = GetStorage();

  /// Latest log always at index 0
  final logs = <PeriodLog>[].obs;

  final averageCycleLength = 28.obs;

  final predictedNextPeriod = DateTime.now().obs;

  final periodDuration = 5.obs;

  // ================= INIT =================

  @override
  void onInit() {
    super.onInit();

    _loadLogs();

    /// Auto save + auto recalc
    ever<List<PeriodLog>>(logs, (_) {
      _saveLogs();
      _calculateStats();
    });

    _calculateStats();
  }

  // ================= STORAGE =================

  void _loadLogs() {
    final stored = storage.read('period_logs');

    if (stored != null && stored is List) {
      logs.assignAll(
        stored
            .map((e) => PeriodLog.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

      /// Keep newest first
      logs.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  void _saveLogs() {
    storage.write('period_logs', logs.map((e) => e.toJson()).toList());
  }

  // ================= ACTIONS =================

  bool checkIsOutlier(DateTime newDate) {
    if (logs.isEmpty) return false;

    final lastDate = logs.first.date;

    final diff = newDate.difference(lastDate).inDays.abs();

    /// medically reasonable cycle warning
    return diff < 21 || diff > 35;
  }

  void logPeriod(DateTime date, {bool ignoreForPrediction = false}) {
    /// avoid duplicates
    if (logs.any((log) => _isSameDay(log.date, date))) {
      return;
    }

    logs.add(PeriodLog(date: date, isIgnored: ignoreForPrediction));

    /// newest first
    logs.sort((a, b) => b.date.compareTo(a.date));
  }

  void deleteLog(DateTime date) {
    logs.removeWhere((log) => _isSameDay(log.date, date));
  }

  // ================= CALCULATIONS =================

  void _calculateStats() {
    if (logs.isEmpty) {
      predictedNextPeriod.value = DateTime.now();
      averageCycleLength.value = 28;
      return;
    }

    /// only 1 log → default prediction
    if (logs.length < 2) {
      predictedNextPeriod.value = logs.first.date.add(
        Duration(days: averageCycleLength.value),
      );
      return;
    }

    List<int> cycleLengths = [];

    for (int i = 0; i < logs.length - 1; i++) {
      if (logs[i].isIgnored) continue;

      final gap = logs[i].date.difference(logs[i + 1].date).inDays;

      /// ignore unrealistic data
      if (gap >= 15 && gap <= 60) {
        cycleLengths.add(gap);
      }
    }

    if (cycleLengths.isEmpty) {
      averageCycleLength.value = 28;
    } else {
      double weightedSum = 0;
      double totalWeight = 0;

      /// recent cycles weighted higher
      for (int i = 0; i < cycleLengths.length; i++) {
        double weight;

        if (i == 0) {
          weight = 0.5;
        } else if (i == 1) {
          weight = 0.3;
        } else {
          weight = 0.2;
        }

        weightedSum += cycleLengths[i] * weight;

        totalWeight += weight;
      }

      averageCycleLength.value = (weightedSum / totalWeight).round();
    }

    predictedNextPeriod.value = logs.first.date.add(
      Duration(days: averageCycleLength.value),
    );
  }

  // ================= HELPERS =================

  /// confirmed logged period
  bool isPeriodDay(DateTime date) {
    for (final log in logs) {
      final diff = date.difference(log.date).inDays;

      if (diff >= 0 && diff < periodDuration.value) {
        return true;
      }
    }
    return false;
  }

  /// predicted next period only
  bool isPredictedPeriodDay(DateTime date) {
    if (logs.isEmpty) return false;

    final diff = date.difference(predictedNextPeriod.value).inDays;

    return diff >= 0 && diff < periodDuration.value;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
