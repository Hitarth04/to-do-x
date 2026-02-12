class Task {
  String id;
  String title;
  DateTime date;
  bool isHighPriority;
  bool isCompleted;
  DateTime? completedAt;
  bool isReminderEnabled;
  int reminderMinutesBefore;
  String category;
  int color; // We store color as an integer (e.g., 0xFF42A5F5)

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.isHighPriority = false,
    this.isCompleted = false,
    this.completedAt,
    this.isReminderEnabled = false,
    this.reminderMinutesBefore = 0,
    // Defaults
    this.category = 'General',
    this.color = 0xFF9E9E9E, // Grey
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
    isReminderEnabled: json['isReminderEnabled'] ?? false,
    reminderMinutesBefore: json['reminderMinutesBefore'] ?? 0,
    // Map new fields
    category: json['category'] ?? 'General',
    color: json['color'] ?? 0xFF9E9E9E,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'isHighPriority': isHighPriority,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'isReminderEnabled': isReminderEnabled,
    'reminderMinutesBefore': reminderMinutesBefore,
    // Save new fields
    'category': category,
    'color': color,
  };
}
