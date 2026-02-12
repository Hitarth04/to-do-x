import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_colors.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String time;
  final bool isHigh;
  final bool isDone;
  final String category;
  final int color;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const TaskCard({
    super.key,
    required this.title,
    required this.time,
    required this.onToggle,
    required this.onEdit,
    required this.category,
    required this.color,
    this.isHigh = false,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    // Detect theme brightness for fine-tuning
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors from the Theme we set up
    final cardBgColor = Theme.of(context).cardColor;
    final mainTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = isDark ? Colors.grey[400] : AppColors.textGrey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: cardBgColor, // Automatically switches between White and #1E1E1E
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Category Strip
            Container(
              width: 6,
              color: isDone ? Colors.grey.shade300 : Color(color),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                        onTap: onEdit,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDone
                                    ? subTextColor
                                    : mainTextColor, // White in Dark Mode
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                // Category Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Color(color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  time,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isHigh && !isDone)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.priority_high,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),

                    // Edit Button
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: subTextColor,
                        size: 20,
                      ),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
