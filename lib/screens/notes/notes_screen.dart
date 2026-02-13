import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

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
      body: Column(
        children: [
          // 1. SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: "Search your notes...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),

          // 2. NOTES GRID
          Expanded(
            child: Obx(() {
              final notesList = controller.filteredNotes;
              return notesList.isEmpty
                  ? Center(
                      child: Text(
                        "No notes found",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                  : MasonryGridView.count(
                      padding: const EdgeInsets.all(12),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      itemCount: notesList.length,
                      itemBuilder: (context, index) {
                        final note = notesList[index];
                        return _buildNoteCard(context, note);
                      },
                    );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(
          () => const NoteEditorScreen(),
          transition: Transition.fadeIn,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, Note note) {
    final hasBgImage = note.backgroundImagePath != null;
    // FIX: If color is 0, use Card Color (Grey/White), else use the pastel color
    final Color cardColor = note.color == 0
        ? Theme.of(context).cardColor
        : Color(note.color);
    // FIX: Text color logic
    final Color textColor = (hasBgImage || note.color == 0)
        ? (Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87)
        : Colors.black87; // Pastel always black text

    return GestureDetector(
      onTap: () => Get.to(
        () => NoteEditorScreen(note: note),
        transition: Transition.fadeIn,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: hasBgImage ? Colors.transparent : cardColor,
          image: hasBgImage
              ? DecorationImage(
                  image: FileImage(File(note.backgroundImagePath!)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.contentImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(note.contentImages.first),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            if (note.title.isNotEmpty)
              Text(
                note.title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textColor,
                ),
              ),

            const SizedBox(height: 8),

            if (note.isTodoList)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: note.todoItems
                    .take(3)
                    .map(
                      (item) => Row(
                        children: [
                          Icon(
                            item['done']
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 14,
                            color: textColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item['text'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              )
            else
              Text(
                note.content,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textColor.withOpacity(0.8),
                ),
              ),

            const SizedBox(height: 10),
            Text(
              DateFormat('MMM dd').format(note.date),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: textColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
//           THE EDITOR
// ==========================================

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NotesController controller = Get.find<NotesController>();

  late TextEditingController titleCtrl;
  late TextEditingController contentCtrl;

  String? _bgImagePath;
  int _selectedColor = 0; // 0 = Default (Grey/Theme)
  List<String> _attachedImages = [];
  bool _isTodoList = false;
  List<Map<String, dynamic>> _todoItems = [];

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.note?.title ?? "");
    contentCtrl = TextEditingController(text: widget.note?.content ?? "");

    _bgImagePath = widget.note?.backgroundImagePath;
    // FIX: Default to 0 (Theme Color) instead of forcing Yellow
    _selectedColor = widget.note?.color ?? 0;
    _attachedImages = List.from(widget.note?.contentImages ?? []);
    _isTodoList = widget.note?.isTodoList ?? false;
    _todoItems = List.from(widget.note?.todoItems ?? []);

    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    bool isEmpty =
        titleCtrl.text.isEmpty &&
        contentCtrl.text.isEmpty &&
        _attachedImages.isEmpty &&
        _todoItems.isEmpty;

    if (isEmpty) {
      if (widget.note != null) controller.deleteNote(widget.note!.id);
    } else {
      final newNote = Note(
        id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleCtrl.text,
        content: contentCtrl.text,
        date: DateTime.now(),
        color: _selectedColor,
        backgroundImagePath: _bgImagePath,
        contentImages: _attachedImages,
        isTodoList: _isTodoList,
        todoItems: _todoItems,
      );

      if (widget.note == null) {
        controller.addNote(newNote);
      } else {
        controller.updateNote(widget.note!, newNote);
      }
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Color Resolution Logic
    Color bgColor;
    if (_bgImagePath != null) {
      bgColor = Colors.transparent;
    } else if (_selectedColor == 0) {
      bgColor = Theme.of(context).cardColor; // The "Grey" you liked
    } else {
      bgColor = Color(_selectedColor);
    }

    // FIX: Text Color Resolution Logic
    Color textColor;
    if (_bgImagePath != null) {
      textColor = Colors.white;
    } else if (_selectedColor == 0) {
      // If default/grey, adapt to theme (White in Dark, Black in Light)
      textColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87;
    } else {
      textColor = Colors.black87; // Pastel always gets black
    }

    final Color iconColor = textColor.withOpacity(0.7);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _saveAndClose();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: iconColor),
            onPressed: _saveAndClose,
          ),
          actions: [
            if (widget.note != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: iconColor),
                onPressed: () {
                  controller.deleteNote(widget.note!.id);
                  Get.back();
                },
              ),
          ],
        ),
        body: Container(
          decoration: _bgImagePath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(_bgImagePath!)),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                )
              : null,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                  children: [
                    if (_attachedImages.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  children: [
                                    Image.file(
                                      File(_attachedImages[index]),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _attachedImages.removeAt(index),
                                        ),
                                        child: const CircleAvatar(
                                          backgroundColor: Colors.red,
                                          radius: 10,
                                          child: Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: "Title",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                      ),
                    ),

                    if (_isTodoList)
                      _buildChecklist(textColor)
                    else
                      TextField(
                        controller: contentCtrl,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: textColor,
                        ),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "Note something down...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              _buildBottomBar(iconColor),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildChecklist(Color textColor) {
    return Column(
      children: [
        ..._todoItems.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return Row(
            children: [
              Checkbox(
                value: item['done'],
                activeColor: textColor,
                checkColor:
                    _selectedColor == 0 &&
                        Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                side: BorderSide(color: textColor),
                onChanged: (val) {
                  setState(() => item['done'] = val);
                },
              ),
              Expanded(
                child: TextFormField(
                  initialValue: item['text'],
                  style: TextStyle(
                    color: textColor,
                    decoration: item['done']
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (val) => item['text'] = val,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: textColor.withOpacity(0.5),
                ),
                onPressed: () => setState(() => _todoItems.removeAt(idx)),
              ),
            ],
          );
        }).toList(),
        TextButton.icon(
          onPressed: () =>
              setState(() => _todoItems.add({'text': '', 'done': false})),
          icon: Icon(Icons.add, color: textColor),
          label: Text("Add Item", style: TextStyle(color: textColor)),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.palette_outlined, color: iconColor),
            tooltip: "Background",
            onPressed: _showBackgroundPicker,
          ),
          IconButton(
            icon: Icon(Icons.image_outlined, color: iconColor),
            tooltip: "Add Image",
            onPressed: _pickImage,
          ),
          IconButton(
            icon: Icon(
              _isTodoList ? Icons.format_align_left : Icons.check_box_outlined,
              color: iconColor,
            ),
            tooltip: "Toggle Checklist",
            onPressed: () {
              setState(() {
                _isTodoList = !_isTodoList;
                if (_isTodoList && contentCtrl.text.isNotEmpty) {
                  _todoItems = contentCtrl.text
                      .split('\n')
                      .map((e) => {'text': e, 'done': false})
                      .toList();
                } else if (!_isTodoList && _todoItems.isNotEmpty) {
                  contentCtrl.text = _todoItems
                      .map((e) => e['text'])
                      .join('\n');
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.mic_none,
              color: _isListening ? Colors.red : iconColor,
            ),
            tooltip: "Voice to Text",
            onPressed: _listen,
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: iconColor),
            tooltip: "Share",
            onPressed: () {
              final text =
                  "${titleCtrl.text}\n\n${_isTodoList ? _todoItems.map((e) => "- ${e['text']}").join('\n') : contentCtrl.text}";
              Share.share(text);
            },
          ),
        ],
      ),
    );
  }

  // --- ACTIONS ---

  void _showBackgroundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text("Choose Background"),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  // 1. DEFAULT (Reset to Grey/Theme)
                  GestureDetector(
                    onTap: () => setState(() {
                      _bgImagePath = null;
                      _selectedColor = 0;
                      Navigator.pop(ctx);
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        child: Icon(
                          Icons.format_color_reset,
                          color: Theme.of(context).iconTheme.color,
                        ),
                      ),
                    ),
                  ),
                  // 2. Image Picker
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final XFile? image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null)
                        setState(() => _bgImagePath = image.path);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.image, color: Colors.white),
                      ),
                    ),
                  ),
                  // 3. Colors
                  ...controller.pastelColors.map(
                    (color) => GestureDetector(
                      onTap: () => setState(() {
                        _bgImagePath = null;
                        _selectedColor = color;
                        Navigator.pop(ctx);
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Color(color),
                          radius: 25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() => _attachedImages.add(image.path));
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              if (_isTodoList && _todoItems.isNotEmpty) {
                _todoItems.last['text'] = val.recognizedWords;
              } else {
                contentCtrl.text += " ${val.recognizedWords}";
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}
