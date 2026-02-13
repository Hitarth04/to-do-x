import 'dart:math';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../data/models/note_model.dart';

class NotesController extends GetxController {
  var notes = <Note>[].obs;
  var searchQuery = ''.obs;
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

  // UPDATED: Search + Sorting Logic
  List<Note> get filteredNotes {
    List<Note> result;

    // 1. Filter by Search
    if (searchQuery.value.isEmpty) {
      result = [...notes];
    } else {
      result = notes.where((note) {
        return note.title.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            note.content.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            );
      }).toList();
    }

    // 2. Sort: Pinned First, then Newest Date First
    result.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1; // a comes first
      if (!a.isPinned && b.isPinned) return 1; // b comes first
      return b.date.compareTo(a.date); // If pin state is same, sort by date
    });

    return result;
  }

  void addNote(Note note) {
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
