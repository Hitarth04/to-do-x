import 'dart:math';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/note_model.dart';

class NotesController extends GetxController {
  var notes = <Note>[].obs;
  var searchQuery = ''.obs; // Search State
  final storage = GetStorage();

  final List<int> pastelColors = [
    0xFFFFF8B8,
    0xFFF28B82,
    0xFFCCFF90,
    0xFFA7FFEB,
    0xFFCBF0F8,
    0xFFAFCBFA,
    0xFFD7AEFB,
    0xFFFDCFE8,
    0xFFE6C9A8,
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

  // SEARCH LOGIC
  List<Note> get filteredNotes {
    if (searchQuery.value.isEmpty) return notes;
    return notes.where((note) {
      return note.title.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          note.content.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  void addNote(Note note) {
    // If no color assigned, pick random
    if (note.color == 0) {
      note.color = pastelColors[Random().nextInt(pastelColors.length)];
    }
    notes.add(note);
  }

  void updateNote(Note oldNote, Note newNote) {
    var index = notes.indexWhere((n) => n.id == oldNote.id);
    if (index != -1) {
      notes[index] = newNote;
      notes.refresh();
    }
  }

  void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
  }

  void restoreNote(Note note) {
    notes.add(note);
    notes.refresh();
  }
}
