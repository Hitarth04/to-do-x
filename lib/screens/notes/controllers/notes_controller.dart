import 'dart:math';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/note_model.dart';

class NotesController extends GetxController {
  var notes = <Note>[].obs;
  final storage = GetStorage();

  final List<int> pastelColors = [
    0xFFFFF8B8, // Yellow
    0xFFF28B82, // Red/Pink
    0xFFCCFF90, // Green
    0xFFA7FFEB, // Teal
    0xFFCBF0F8, // Cyan
    0xFFAFCBFA, // Blue
    0xFFD7AEFB, // Purple
    0xFFFDCFE8, // Pink
    0xFFE6C9A8, // Brown
  ];

  @override
  void onInit() {
    super.onInit();
    var storedNotes = storage.read<List>('notes');
    if (storedNotes != null) {
      notes.assignAll(storedNotes.map((e) => Note.fromJson(e)).toList());
    }
    ever(notes, (_) {
      storage.write('notes', notes.map((e) => e.toJson()).toList());
    });
  }

  void addNote(String title, String content) {
    int randomColor = pastelColors[Random().nextInt(pastelColors.length)];

    notes.add(
      Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: content,
        date: DateTime.now(),
        color: randomColor,
      ),
    );
  }

  void updateNote(Note note, String title, String content) {
    var index = notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      notes[index] = Note(
        id: note.id,
        title: title,
        content: content,
        date: DateTime.now(),
        color: note.color,
      );
      notes.refresh();
    }
  }

  void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
  }

  // NEW: Restore function for Undo
  void restoreNote(Note note) {
    notes.add(note);
    notes.refresh();
  }
}
