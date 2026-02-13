import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../data/models/note_model.dart';
import 'controllers/notes_controller.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final NotesController controller = Get.put(NotesController());

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: Text(
          'My Notes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(
        () => controller.notes.isEmpty
            ? Center(
                child: Text(
                  "No notes yet",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: controller.notes.length,
                  itemBuilder: (context, index) {
                    final note = controller.notes[index];
                    return GestureDetector(
                      onTap: () => _showNoteEditor(context, note: note),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(note.color),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (note.title.isNotEmpty)
                              Text(
                                note.title,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            if (note.title.isNotEmpty)
                              const SizedBox(height: 8),
                            Text(
                              note.content,
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              DateFormat('MMM dd').format(note.date),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, {Note? note}) {
    final NotesController controller = Get.find<NotesController>();
    final titleCtrl = TextEditingController(text: note?.title ?? "");
    final contentCtrl = TextEditingController(text: note?.content ?? "");

    // COLOR LOGIC:
    // If Editing (note != null): Background is Pastel -> Text MUST be Black.
    // If Creating (note == null): Background is Theme Card -> Text follows Theme (White in Dark Mode).
    final Color bgColor = note != null
        ? Color(note.color)
        : Theme.of(context).cardColor;
    final Color textColor = note != null
        ? Colors.black87
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final Color iconColor = note != null
        ? Colors.black
        : Theme.of(context).iconTheme.color ?? Colors.black;
    final Color hintColor = note != null ? Colors.black26 : Colors.grey;

    Get.to(
      () => Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: () {
              // Auto-Save logic
              if (titleCtrl.text.isNotEmpty || contentCtrl.text.isNotEmpty) {
                if (note == null) {
                  controller.addNote(titleCtrl.text, contentCtrl.text);
                } else {
                  controller.updateNote(note, titleCtrl.text, contentCtrl.text);
                }
              }
              Get.back();
            },
          ),
          actions: [
            if (note != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconColor),
                onPressed: () {
                  // 1. Capture note for Undo
                  final deletedNote = note;

                  // 2. Delete it
                  controller.deleteNote(note.id);
                  Get.back(); // Close editor

                  // 3. Show Undo Snackbar
                  Get.snackbar(
                    "Note Deleted",
                    "The note was removed",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.black87,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(10),
                    duration: const Duration(seconds: 4),
                    mainButton: TextButton(
                      onPressed: () {
                        controller.restoreNote(deletedNote);
                        if (Get.isSnackbarOpen) Get.back();
                      },
                      child: const Text(
                        "UNDO",
                        style: TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                // Apply Dynamic Text Color
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: "Title",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: hintColor),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: contentCtrl,
                  // Apply Dynamic Text Color
                  style: GoogleFonts.poppins(fontSize: 16, color: textColor),
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: "Note something down...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: hintColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      transition: Transition.fadeIn,
    );
  }
}
