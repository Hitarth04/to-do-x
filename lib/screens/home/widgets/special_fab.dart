import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_x/core/app_colors.dart';

class SpeedDialFab extends StatefulWidget {
  final VoidCallback onTask;
  final VoidCallback onNote;

  const SpeedDialFab({super.key, required this.onTask, required this.onNote});

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Note Button
        ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: FloatingActionButton.extended(
              heroTag: 'note_fab',
              onPressed: () {
                toggle();
                widget.onNote();
              },
              backgroundColor: Colors.amber[200],
              foregroundColor: Colors.black,
              label: Text(
                "Note",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.note_alt_outlined),
            ),
          ),
        ),

        // Task Button
        ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: FloatingActionButton.extended(
              heroTag: 'task_fab',
              onPressed: () {
                toggle();
                widget.onTask();
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              label: Text(
                "Task",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.check),
            ),
          ),
        ),

        // Main FAB (The Toggle)
        FloatingActionButton(
          heroTag: 'main_fab',
          backgroundColor: isExpanded ? Colors.grey : AppColors.primary,
          onPressed: toggle,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
