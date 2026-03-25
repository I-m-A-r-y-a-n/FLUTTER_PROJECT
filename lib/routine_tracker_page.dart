import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class RoutineTrackerPage extends StatefulWidget {
  const RoutineTrackerPage({super.key});

  @override
  State<RoutineTrackerPage> createState() => _RoutineTrackerPageState();
}

class _RoutineTrackerPageState extends State<RoutineTrackerPage> {
  final List<String> predefinedTypes = [
    'Study',
    'Exercise',
    'Sleep',
    'Game',
    'Entertainment',
    'Other',
  ];

  final Map<String, IconData> routineIcons = {
    'Study': Icons.menu_book,
    'Exercise': Icons.fitness_center,
    'Sleep': Icons.bedtime,
    'Game': Icons.sports_esports,
    'Entertainment': Icons.movie,
    'Other': Icons.star,
  };

  final Map<String, Color> routineColors = {
    'Study': Color(0xFF6549F3),
    'Exercise': Colors.orange,
    'Sleep': Colors.indigo,
    'Game': Colors.green,
    'Entertainment': Colors.pink,
    'Other': Colors.teal,
  };

  String get today => DateTime.now().toIso8601String().substring(0, 10);

  String _formatDate() {
    final now = DateTime.now();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}";
  }

  // ─── CALCULATE STREAK ───────────────────────────
  int _calculateStreak(Map completedDates) {
    if (completedDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.now();

    // If today not done, start checking from yesterday
    final todayStr = checkDate.toIso8601String().substring(0, 10);
    if (!completedDates.containsKey(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Count consecutive days backwards
    while (true) {
      final dateStr = checkDate.toIso8601String().substring(0, 10);
      if (completedDates.containsKey(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── ADD ROUTINE DIALOG ─────────────────────────
  void showAddRoutineDialog() {
    String selectedType = predefinedTypes[0];
    bool isCustom = false;
    final customController = TextEditingController();
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Routine",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle predefined vs custom
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setDialogState(() => isCustom = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: !isCustom
                              ? const Color(0xFF6549F3)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("Predefined",
                            style: TextStyle(
                              color: !isCustom ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setDialogState(() => isCustom = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isCustom
                              ? const Color(0xFF6549F3)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text("Custom",
                            style: TextStyle(
                              color: isCustom ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Predefined list OR custom input
                if (!isCustom) ...[
                  const Text("Select Type",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedTypes.map((type) {
                      final isSelected = selectedType == type;
                      final color =
                          routineColors[type] ?? const Color(0xFF6549F3);
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? color : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                routineIcons[type] ?? Icons.star,
                                size: 14,
                                color:
                                    isSelected ? Colors.white : Colors.black54,
                              ),
                              const SizedBox(width: 5),
                              Text(type,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const Text("Custom Name",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: customController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "e.g. Meditation, Reading...",
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Time picker
                const Text("Target Time (optional)",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          selectedTime == null
                              ? "Pick a time"
                              : selectedTime!.format(context),
                          style: TextStyle(
                            color: selectedTime == null
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String finalType =
                    isCustom ? customController.text.trim() : selectedType;
                if (finalType.isEmpty) return;

                final timeStr =
                    selectedTime == null ? '' : selectedTime!.format(context);

                await DatabaseService.addRoutine(finalType, timeStr);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6549F3)),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DELETE CONFIRMATION ─────────────────────────
  void confirmDelete(String routineId, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Routine"),
        content: Text('Delete "$type" routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteRoutine(routineId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDE0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Routine Tracker",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddRoutineDialog,
        backgroundColor: const Color(0xFF6549F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: DatabaseService.getRoutinesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value;
          final Map<String, dynamic> routinesMap =
              data != null ? Map<String, dynamic>.from(data as Map) : {};
          final entries = routinesMap.entries.toList();

          // Count today's completions
          int doneToday = 0;
          for (final e in entries) {
            final r = Map<String, dynamic>.from(e.value as Map);
            final completed = r['completedDates'] != null
                ? Map<String, dynamic>.from(r['completedDates'] as Map)
                : {};
            if (completed.containsKey(today)) doneToday++;
          }

          return Column(
            children: [
              // ─── TODAY HEADER ──────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6549F3), Color(0xFF4FC3FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(),
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entries.isEmpty
                          ? "Add your first routine!"
                          : "$doneToday / ${entries.length} routines done today",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (entries.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value:
                              entries.isEmpty ? 0 : doneToday / entries.length,
                          backgroundColor: Colors.white30,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ─── ROUTINE LIST ──────────────────────
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.repeat,
                                size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              "No routines yet\nTap + to add one!",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final routineData =
                              Map<String, dynamic>.from(entry.value as Map);
                          final String type = routineData['type'] ?? 'Other';
                          final String scheduledTime =
                              routineData['scheduledTime'] ?? '';
                          final Map completedDates =
                              routineData['completedDates'] != null
                                  ? Map.from(
                                      routineData['completedDates'] as Map)
                                  : {};

                          final bool doneToday =
                              completedDates.containsKey(today);
                          final int streak = _calculateStreak(completedDates);

                          // Get color and icon
                          final color =
                              routineColors[type] ?? const Color(0xFF6549F3);
                          final icon = routineIcons[type] ?? Icons.star;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(color: color, width: 4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 22),
                                ),
                                const SizedBox(width: 12),

                                // Type + time + streak
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        type,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          if (scheduledTime.isNotEmpty) ...[
                                            Icon(Icons.access_time,
                                                size: 12, color: Colors.grey),
                                            const SizedBox(width: 3),
                                            Text(scheduledTime,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                            const SizedBox(width: 10),
                                          ],
                                          // Streak
                                          Text(
                                            streak > 0
                                                ? "🔥 $streak day streak"
                                                : "No streak yet",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: streak > 0
                                                  ? Colors.orange
                                                  : Colors.grey,
                                              fontWeight: streak > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Done button + delete
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: doneToday
                                          ? null
                                          : () =>
                                              DatabaseService.markRoutineToday(
                                                  entry.key),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color:
                                              doneToday ? Colors.green : color,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          doneToday ? "✓ Done" : "Mark",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () =>
                                          confirmDelete(entry.key, type),
                                      child: const Icon(Icons.delete_outline,
                                          color: Colors.grey, size: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
