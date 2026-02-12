import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isHigh;
  final bool isDone;
  final VoidCallback onToggle;
  final VoidCallback onEdit; // NEW: Callback for editing

  const TaskCard({
    super.key,
    required this.title,
    required this.time,
    required this.onToggle,
    required this.onEdit, // NEW: Require it
    this.isHigh = false,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Time
          Expanded(
            child: GestureDetector(
              onTap: onEdit, // NEW: Tapping text also opens edit
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? AppColors.textGrey : Colors.black87,
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Priority Icon
          if (isHigh && !isDone)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.priority_high, color: Colors.red, size: 20),
            ),

          // NEW: Edit Icon Button
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
