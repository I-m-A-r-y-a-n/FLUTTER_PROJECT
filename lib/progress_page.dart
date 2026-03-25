import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  // ─── STREAK CALCULATION ──────────────────────────
  int _calcStreak(Map completedDates) {
    if (completedDates.isEmpty) return 0;
    final today = DateTime.now();
    int streak = 0;
    DateTime checking = DateTime(today.year, today.month, today.day);
    while (true) {
      final key =
          "${checking.year}-${checking.month.toString().padLeft(2, '0')}-${checking.day.toString().padLeft(2, '0')}";
      if (completedDates.containsKey(key)) {
        streak++;
        checking = checking.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── CONSISTENCY % (last 7 days) ─────────────────
  double _calcConsistency(Map completedDates) {
    int done = 0;
    final today = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final d = today.subtract(Duration(days: i));
      final key =
          "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      if (completedDates.containsKey(key)) done++;
    }
    return done / 7;
  }

  // ─── ROUTINE ICON ────────────────────────────────
  IconData _routineIcon(String type) {
    switch (type.toLowerCase()) {
      case 'study':
        return Icons.menu_book;
      case 'exercise':
        return Icons.fitness_center;
      case 'sleep':
        return Icons.bedtime;
      case 'game':
        return Icons.sports_esports;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.repeat;
    }
  }

  Color _routineColor(String type) {
    switch (type.toLowerCase()) {
      case 'study':
        return const Color(0xFF6549F3);
      case 'exercise':
        return Colors.orange;
      case 'sleep':
        return Colors.indigo;
      case 'game':
        return Colors.green;
      case 'entertainment':
        return Colors.pink;
      default:
        return Colors.teal;
    }
  }

  // ─── LAST 7 DAYS DOTS ────────────────────────────
  Widget _weekDots(Map completedDates) {
    final today = DateTime.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(7, (i) {
        final d = today.subtract(Duration(days: 6 - i));
        final key =
            "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        final done = completedDates.containsKey(key);
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? Colors.green : Colors.grey.shade300,
          ),
        );
      }),
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
        title: const Text("Progress",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ROUTINES SECTION ──────────────────────
            _sectionHeader(
                Icons.repeat, "Routine Streaks", const Color(0xFF6549F3)),
            const SizedBox(height: 12),

            StreamBuilder<DatabaseEvent>(
              stream: DatabaseService.getRoutinesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data?.snapshot.value;
                final Map<String, dynamic> routinesMap =
                    data != null ? Map<String, dynamic>.from(data as Map) : {};

                if (routinesMap.isEmpty) {
                  return _emptyCard(
                      "No routines added yet.\nGo to Routine Tracker to add some!");
                }

                final entries = routinesMap.entries.toList();

                // Overall consistency
                double totalConsistency = 0;
                for (final e in entries) {
                  final r = Map<String, dynamic>.from(e.value as Map);
                  final completed = r['completedDates'] != null
                      ? Map<String, dynamic>.from(r['completedDates'] as Map)
                      : {};
                  totalConsistency += _calcConsistency(completed);
                }
                final avgConsistency =
                    entries.isEmpty ? 0.0 : totalConsistency / entries.length;

                return Column(
                  children: [
                    // Overall consistency card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6549F3), Color(0xFF4FC3FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Overall Consistency (7 days)",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Text("${(avgConsistency * 100).toInt()}%",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: avgConsistency,
                              minHeight: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Individual routine cards
                    ...entries.map((e) {
                      final r = Map<String, dynamic>.from(e.value as Map);
                      final type = r['type'] ?? 'Other';
                      final scheduledTime = r['scheduledTime'] ?? '';
                      final completed = r['completedDates'] != null
                          ? Map<String, dynamic>.from(
                              r['completedDates'] as Map)
                          : {};
                      final streak = _calcStreak(completed);
                      final consistency = _calcConsistency(completed);
                      final color = _routineColor(type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border(left: BorderSide(color: color, width: 4)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(_routineIcon(type),
                                      color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(type,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                      if (scheduledTime.isNotEmpty)
                                        Text(scheduledTime,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                // Streak badge
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: streak > 0
                                            ? Colors.orange.withOpacity(0.15)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(children: [
                                        Text(streak > 0 ? "🔥" : "💤",
                                            style:
                                                const TextStyle(fontSize: 14)),
                                        const SizedBox(width: 4),
                                        Text(
                                          streak > 0
                                              ? "$streak day streak"
                                              : "No streak",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: streak > 0
                                                ? Colors.orange
                                                : Colors.grey,
                                          ),
                                        ),
                                      ]),
                                    ),
                                    const SizedBox(height: 6),
                                    _weekDots(completed),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: consistency,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        consistency >= 0.8
                                            ? Colors.green
                                            : consistency >= 0.5
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "${(consistency * 100).toInt()}%",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: consistency >= 0.8
                                          ? Colors.green
                                          : consistency >= 0.5
                                              ? Colors.orange
                                              : Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Last 7 days consistency",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // ── EXAMS SECTION ─────────────────────────
            _sectionHeader(
                Icons.school, "Exam Syllabus Coverage", Colors.deepOrange),
            const SizedBox(height: 12),

            StreamBuilder<DatabaseEvent>(
              stream: DatabaseService.getExamsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data?.snapshot.value;
                final Map<String, dynamic> examsMap =
                    data != null ? Map<String, dynamic>.from(data as Map) : {};

                if (examsMap.isEmpty) {
                  return _emptyCard(
                      "No exams added yet.\nGo to Exams to add some!");
                }

                final entries = examsMap.entries.toList();
                entries.sort((a, b) {
                  final da =
                      Map<String, dynamic>.from(a.value as Map)['date'] ?? '';
                  final db =
                      Map<String, dynamic>.from(b.value as Map)['date'] ?? '';
                  return da.compareTo(db);
                });

                // Overall coverage
                int totalTopics = 0;
                int totalDone = 0;
                for (final e in entries) {
                  final exam = Map<String, dynamic>.from(e.value as Map);
                  final syllabus = exam['syllabus'] != null
                      ? Map<String, dynamic>.from(exam['syllabus'] as Map)
                      : {};
                  totalTopics += syllabus.length;
                  totalDone += syllabus.values.where((t) {
                    final topic = Map<String, dynamic>.from(t as Map);
                    return topic['isDone'] == true;
                  }).length;
                }
                final overallCoverage =
                    totalTopics == 0 ? 0.0 : totalDone / totalTopics;

                return Column(
                  children: [
                    // Overall coverage card
                    if (totalTopics > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepOrange, Colors.orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Overall Syllabus Coverage",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${(overallCoverage * 100).toInt()}%",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                      "($totalDone / $totalTopics topics)",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: overallCoverage,
                                minHeight: 8,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Per exam cards
                    ...entries.map((e) {
                      final exam = Map<String, dynamic>.from(e.value as Map);
                      final subject = exam['subject'] ?? '';
                      final date = exam['date'] ?? '';
                      final syllabus = exam['syllabus'] != null
                          ? Map<String, dynamic>.from(exam['syllabus'] as Map)
                          : {};
                      final total = syllabus.length;
                      final done = syllabus.values.where((t) {
                        final topic = Map<String, dynamic>.from(t as Map);
                        return topic['isDone'] == true;
                      }).length;
                      final progress = total == 0 ? 0.0 : done / total;

                      // Countdown
                      String countdown = '';
                      Color countdownColor = Colors.grey;
                      try {
                        final examDate = DateTime.parse(date);
                        final today = DateTime.now();
                        final diff = DateTime(
                                examDate.year, examDate.month, examDate.day)
                            .difference(
                                DateTime(today.year, today.month, today.day))
                            .inDays;
                        if (diff < 0) {
                          countdown = "Completed";
                          countdownColor = Colors.grey;
                        } else if (diff == 0) {
                          countdown = "TODAY!";
                          countdownColor = Colors.red;
                        } else if (diff == 1) {
                          countdown = "Tomorrow!";
                          countdownColor = Colors.orange;
                        } else {
                          countdown = "in $diff days";
                          countdownColor =
                              diff <= 7 ? Colors.orange : Colors.green;
                        }
                      } catch (_) {}

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                              left:
                                  BorderSide(color: countdownColor, width: 4)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(subject,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: countdownColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(countdown,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: countdownColor)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_formatDate(date),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(height: 10),
                            if (total == 0)
                              Text("No syllabus topics added",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                      fontStyle: FontStyle.italic))
                            else ...[
                              Row(children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progress == 1.0
                                            ? Colors.green
                                            : Colors.deepOrange,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text("$done/$total",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: progress == 1.0
                                            ? Colors.green
                                            : Colors.deepOrange)),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                progress == 1.0
                                    ? "✓ All topics covered!"
                                    : "${(progress * 100).toInt()}% covered",
                                style: TextStyle(
                                    fontSize: 11,
                                    color: progress == 1.0
                                        ? Colors.green
                                        : Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      const months = [
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
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return "${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}";
    } catch (_) {
      return dateStr;
    }
  }
}
