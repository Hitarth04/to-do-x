class Note {
  String id;
  String title;
  String content;
  DateTime date;
  int color;
  String? backgroundImagePath;
  List<String> contentImages;
  bool isTodoList;
  List<Map<String, dynamic>> todoItems;

  // NEW: Pin Field
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.color,
    this.backgroundImagePath,
    this.contentImages = const [],
    this.isTodoList = false,
    this.todoItems = const [],
    this.isPinned = false, // Default to false
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    date: DateTime.parse(json['date']),
    color: json['color'],
    backgroundImagePath: json['backgroundImagePath'],
    contentImages: List<String>.from(json['contentImages'] ?? []),
    isTodoList: json['isTodoList'] ?? false,
    todoItems: List<Map<String, dynamic>>.from(json['todoItems'] ?? []),
    isPinned: json['isPinned'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'color': color,
    'backgroundImagePath': backgroundImagePath,
    'contentImages': contentImages,
    'isTodoList': isTodoList,
    'todoItems': todoItems,
    'isPinned': isPinned,
  };
}
