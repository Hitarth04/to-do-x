import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/notification_service.dart';

class PeriodLog {
  DateTime startDate;
  DateTime? endDate;
  bool isIgnored;

  PeriodLog({required this.startDate, this.endDate, this.isIgnored = false});

  factory PeriodLog.fromJson(Map<String, dynamic> json) => PeriodLog(
    startDate: DateTime.parse(json['startDate']),
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    isIgnored: json['isIgnored'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isIgnored': isIgnored,
  };
}

class HealthController extends GetxController {
  final storage = GetStorage();

  final logs = <PeriodLog>[].obs;
  final averageCycleLength = 28.obs;
  final averageBleedLength = 5.obs;
  final predictedNextPeriod = DateTime.now().obs;

  bool get isPeriodActive => logs.isNotEmpty && logs.first.endDate == null;

  @override
  void onInit() {
    super.onInit();
    _loadLogs();
    _calculateStats();

    ever<List<PeriodLog>>(logs, (_) {
      _saveLogs();
      _calculateStats();
      update(['calendar']);
    });
  }

  void _loadLogs() {
    final stored = storage.read('period_logs');
    if (stored != null && stored is List) {
      logs.assignAll(
        stored
            .map((e) => PeriodLog.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
      logs.sort((a, b) => b.startDate.compareTo(a.startDate));
    }
  }

  void _saveLogs() =>
      storage.write('period_logs', logs.map((e) => e.toJson()).toList());

  // ================= ACTIONS =================

  void startPeriod(DateTime date) {
    if (isPeriodActive) return;

    bool ignore = false;
    if (logs.isNotEmpty) {
      final gap = date.difference(logs.first.startDate).inDays;
      if (gap < 21 || gap > 35) ignore = true;
    }

    logs.insert(0, PeriodLog(startDate: date, isIgnored: ignore));

    // NEW: Schedule 7-day reminder
    NotificationService.schedulePeriodReminder(date);
  }

  void endPeriod(DateTime date) {
    if (!isPeriodActive) return;

    if (date.isBefore(logs.first.startDate)) {
      date = logs.first.startDate;
    }

    logs.first.endDate = date;
    logs.refresh();

    // NEW: Cancel reminder since they remembered
    NotificationService.cancelPeriodReminder();
  }

  void deleteLatestLog() {
    if (logs.isNotEmpty) {
      if (isPeriodActive) NotificationService.cancelPeriodReminder();
      logs.removeAt(0);
      update(['calendar']);
    }
  }

  // ================= MATH ENGINE =================

  void _calculateStats() {
    if (logs.isEmpty) {
      predictedNextPeriod.value = DateTime.now();
      return;
    }

    // 1. AUTO-CAP SECURITY
    // If the app is opened and it's been MORE than 7 days (day 8+), auto-cap it.
    if (isPeriodActive) {
      final daysActive = DateTime.now().difference(logs.first.startDate).inDays;
      if (daysActive > 7) {
        int capDays = averageBleedLength.value > 0
            ? averageBleedLength.value
            : 5;
        logs.first.endDate = logs.first.startDate.add(
          Duration(days: capDays - 1),
        );
        NotificationService.cancelPeriodReminder(); // Clean up
      }
    }

    // 2. BLEEDING LENGTH AVERAGE
    List<int> bleedLengths = [];
    for (var log in logs) {
      if (log.endDate != null) {
        bleedLengths.add(log.endDate!.difference(log.startDate).inDays + 1);
      }
    }
    if (bleedLengths.isNotEmpty) {
      averageBleedLength.value =
          (bleedLengths.reduce((a, b) => a + b) / bleedLengths.length).round();
    } else {
      averageBleedLength.value = 5;
    }

    // 3. CYCLE LENGTH AVERAGE (Weighted Math)
    if (logs.length >= 2) {
      List<int> cycleLengths = [];
      for (int i = 0; i < logs.length - 1; i++) {
        if (logs[i].isIgnored) continue;
        final gap = logs[i].startDate.difference(logs[i + 1].startDate).inDays;
        if (gap >= 15 && gap <= 60) cycleLengths.add(gap);
      }

      if (cycleLengths.isNotEmpty) {
        double weightedSum = 0;
        double totalWeight = 0;
        for (int i = 0; i < cycleLengths.length; i++) {
          double weight = (i == 0) ? 0.5 : (i == 1 ? 0.3 : 0.2);
          weightedSum += cycleLengths[i] * weight;
          totalWeight += weight;
        }
        averageCycleLength.value = (weightedSum / totalWeight).round();
      }
    }

    // 4. PREDICT NEXT PERIOD
    predictedNextPeriod.value = logs.first.startDate.add(
      Duration(days: averageCycleLength.value),
    );
  }

  // ================= HELPERS =================

  bool isPeriodDay(DateTime date) {
    DateTime target = _normalize(date);
    for (var log in logs) {
      DateTime start = _normalize(log.startDate);
      DateTime end = log.endDate != null
          ? _normalize(log.endDate!)
          : _normalize(DateTime.now());

      if ((target.isAfter(start) || target.isAtSameMomentAs(start)) &&
          (target.isBefore(end) || target.isAtSameMomentAs(end))) {
        return true;
      }
    }
    return false;
  }

  bool isPredictedPeriodDay(DateTime date) {
    if (logs.isEmpty || isPeriodDay(date)) return false;

    DateTime target = _normalize(date);
    DateTime predictStart = _normalize(predictedNextPeriod.value);
    DateTime predictEnd = predictStart.add(
      Duration(days: averageBleedLength.value - 1),
    );

    if ((target.isAfter(predictStart) ||
            target.isAtSameMomentAs(predictStart)) &&
        (target.isBefore(predictEnd) || target.isAtSameMomentAs(predictEnd))) {
      return true;
    }
    return false;
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
