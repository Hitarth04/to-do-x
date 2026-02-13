class Note {
  String id;
  String title;
  String content;
  DateTime date;
  int color; // The specific pastel color for this note

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.color,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    date: DateTime.parse(json['date']),
    color: json['color'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
    'color': color,
  };
}
