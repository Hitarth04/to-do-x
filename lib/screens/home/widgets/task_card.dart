import 'package:flutter/material.dart';
import '../../../core/app_colors.dart'; // To use your grey text colors
import 'package:google_fonts/google_fonts.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isHigh;
  final bool isDone;
  final VoidCallback onToggle; // Logic: Callback to handle clicks

  const TaskCard({
    super.key,
    required this.title,
    required this.time,
    required this.onToggle,
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
          // 1. Interactive Check Icon
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone ? Colors.green : Colors.grey,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // Logic: Cross out text if done
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

          if (isHigh && !isDone) // Logic: Hide exclamation if task is finished
            const Icon(Icons.priority_high, color: Colors.red, size: 20),
        ],
      ),
    );
  }
}
