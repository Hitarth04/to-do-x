class Task {
  String id;
  String title;
  DateTime date;
  bool isHighPriority;
  bool isCompleted;
  DateTime? completedAt;

  // ADD THESE FIELDS
  bool isReminderEnabled;
  int reminderMinutesBefore;

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.isHighPriority = false,
    this.isCompleted = false,
    this.completedAt,
    // Initialize them
    this.isReminderEnabled = false,
    this.reminderMinutesBefore = 0,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    date: DateTime.parse(json['date']),
    isHighPriority: json['isHighPriority'] ?? false,
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    // Map them from JSON
    isReminderEnabled: json['isReminderEnabled'] ?? false,
    reminderMinutesBefore: json['reminderMinutesBefore'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'isHighPriority': isHighPriority,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    // Map them to JSON
    'isReminderEnabled': isReminderEnabled,
    'reminderMinutesBefore': reminderMinutesBefore,
  };
}
