import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage> {
  // ─── HELPERS ────────────────────────────────────
  String _countdown(String dateStr) {
    try {
      final examDate = DateTime.parse(dateStr);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final examOnly = DateTime(examDate.year, examDate.month, examDate.day);
      final diff = examOnly.difference(todayOnly).inDays;
      if (diff < 0) return "Completed";
      if (diff == 0) return "TODAY!";
      if (diff == 1) return "Tomorrow!";
      return "in $diff days";
    } catch (_) {
      return "";
    }
  }

  Color _countdownColor(String dateStr) {
    try {
      final examDate = DateTime.parse(dateStr);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      final examOnly = DateTime(examDate.year, examDate.month, examDate.day);
      final diff = examOnly.difference(todayOnly).inDays;
      if (diff < 0) return Colors.grey;
      if (diff == 0) return Colors.red;
      if (diff <= 3) return Colors.orange;
      if (diff <= 7) return Colors.amber.shade700;
      return Colors.green;
    } catch (_) {
      return Colors.grey;
    }
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

  // ─── ADD EXAM DIALOG ────────────────────────────
  void showAddExamDialog() {
    final subjectController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? examDate;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Exam",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: subjectController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Subject (e.g. Mathematics, Physics)",
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),

                // Date (required)
                const Text("Exam Date *",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => examDate = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: examDate == null
                              ? Colors.grey.shade400
                              : const Color(0xFF6549F3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today,
                          size: 16,
                          color: examDate == null
                              ? Colors.grey
                              : const Color(0xFF6549F3)),
                      const SizedBox(width: 8),
                      Text(
                        examDate == null
                            ? "Pick exam date"
                            : "${examDate!.day}/${examDate!.month}/${examDate!.year}",
                        style: TextStyle(
                            color:
                                examDate == null ? Colors.grey : Colors.black),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Time (optional)
                Row(children: [
                  const Text("Time ",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text("(optional)",
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null)
                          setDialogState(() => startTime = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          startTime == null
                              ? "Start"
                              : startTime!.format(context),
                          style: TextStyle(
                              color: startTime == null
                                  ? Colors.grey
                                  : Colors.black,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 12, minute: 0),
                        );
                        if (picked != null)
                          setDialogState(() => endTime = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          endTime == null ? "End" : endTime!.format(context),
                          style: TextStyle(
                              color:
                                  endTime == null ? Colors.grey : Colors.black,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Notes (optional)
                Row(children: [
                  const Text("Notes ",
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text("(optional)",
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ]),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "General notes about this exam...",
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (subjectController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a subject")));
                  return;
                }
                if (examDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please pick an exam date")));
                  return;
                }
                final dateStr =
                    "${examDate!.year}-${examDate!.month.toString().padLeft(2, '0')}-${examDate!.day.toString().padLeft(2, '0')}";
                await DatabaseService.addExam(
                  subjectController.text.trim(),
                  dateStr,
                  startTime?.format(context) ?? '',
                  endTime?.format(context) ?? '',
                  notesController.text.trim(),
                );
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

  // ─── ADD SYLLABUS TOPIC DIALOG ──────────────────
  void showAddTopicDialog(String examId) {
    final topicController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Syllabus Topic",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: topicController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "e.g. Chapter 3 – Derivatives",
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (topicController.text.trim().isNotEmpty) {
                await DatabaseService.addSyllabusTopic(
                    examId, topicController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6549F3)),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── DELETE EXAM ─────────────────────────────────
  void confirmDeleteExam(String examId, String subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Exam"),
        content: Text('Delete "$subject" exam and all its syllabus?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteExam(examId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── BUILD EXAM CARD ─────────────────────────────
  Widget _buildExamCard(String examId, Map<String, dynamic> data) {
    final subject = data['subject'] ?? '';
    final date = data['date'] ?? '';
    final startTime = data['startTime'] ?? '';
    final endTime = data['endTime'] ?? '';
    final notes = data['notes'] ?? '';
    final countdown = _countdown(date);
    final countdownColor = _countdownColor(date);
    final isPast = countdown == "Completed";

    // Syllabus topics
    final Map<String, dynamic> syllabusMap = data['syllabus'] != null
        ? Map<String, dynamic>.from(data['syllabus'] as Map)
        : {};
    final topics = syllabusMap.entries.toList();
    final totalTopics = topics.length;
    final doneTopics = topics.where((e) {
      final t = Map<String, dynamic>.from(e.value as Map);
      return t['isDone'] == true;
    }).length;
    final progress = totalTopics == 0 ? 0.0 : doneTopics / totalTopics;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isPast ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: isPast ? Colors.grey : countdownColor,
            width: 5,
          ),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(children: [
              Expanded(
                child: Text(subject,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isPast ? Colors.grey : Colors.black,
                    )),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: countdownColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(countdown,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: countdownColor,
                    )),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => confirmDeleteExam(examId, subject),
                child: const Icon(Icons.delete_outline,
                    color: Colors.grey, size: 20),
              ),
            ]),
            const SizedBox(height: 8),

            // Date
            Row(children: [
              Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(_formatDate(date),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            ]),

            // Time (only if set)
            if (startTime.isNotEmpty || endTime.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  startTime.isNotEmpty && endTime.isNotEmpty
                      ? "$startTime – $endTime"
                      : startTime.isNotEmpty
                          ? "Starts $startTime"
                          : "Ends $endTime",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ]),
            ],

            // Notes
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 14, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(notes,
                          style: TextStyle(
                              fontSize: 12, color: Colors.blue.shade900)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Syllabus header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.checklist,
                      size: 16, color: Color(0xFF6549F3)),
                  const SizedBox(width: 6),
                  const Text("Syllabus",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  if (totalTopics > 0) ...[
                    const SizedBox(width: 8),
                    Text("$doneTopics/$totalTopics",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ]),
                GestureDetector(
                  onTap: () => showAddTopicDialog(examId),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6549F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(children: [
                      Icon(Icons.add, size: 14, color: Color(0xFF6549F3)),
                      SizedBox(width: 3),
                      Text("Add Topic",
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6549F3),
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ),

            // Progress bar
            if (totalTopics > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0 ? Colors.green : const Color(0xFF6549F3),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progress == 1.0
                    ? "✓ All topics covered!"
                    : "${(progress * 100).toInt()}% covered",
                style: TextStyle(
                  fontSize: 11,
                  color: progress == 1.0 ? Colors.green : Colors.grey.shade600,
                  fontWeight:
                      progress == 1.0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],

            // Topics list
            if (topics.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...topics.map((topicEntry) {
                final t = Map<String, dynamic>.from(topicEntry.value as Map);
                final topicName = t['name'] ?? '';
                final isDone = t['isDone'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => DatabaseService.toggleSyllabusTopic(
                            examId, topicEntry.key, isDone),
                        child: Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isDone ? Colors.green : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          topicName,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDone ? Colors.grey : Colors.black87,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => DatabaseService.deleteSyllabusTopic(
                            examId, topicEntry.key),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }),
            ],

            if (topics.isEmpty) ...[
              const SizedBox(height: 6),
              Text("No syllabus topics yet — tap 'Add Topic'",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
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
        title: const Text("Exams",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddExamDialog,
        backgroundColor: const Color(0xFF6549F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: DatabaseService.getExamsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value;
          final Map<String, dynamic> examsMap =
              data != null ? Map<String, dynamic>.from(data as Map) : {};

          final entries = examsMap.entries.toList();

          // Sort by date (upcoming first, then past)
          entries.sort((a, b) {
            final da = Map<String, dynamic>.from(a.value as Map)['date'] ?? '';
            final db = Map<String, dynamic>.from(b.value as Map)['date'] ?? '';
            return da.compareTo(db);
          });

          // Split upcoming and past
          final upcoming = entries.where((e) {
            final d = Map<String, dynamic>.from(e.value as Map)['date'] ?? '';
            return _countdown(d) != "Completed";
          }).toList();

          final past = entries.where((e) {
            final d = Map<String, dynamic>.from(e.value as Map)['date'] ?? '';
            return _countdown(d) == "Completed";
          }).toList();

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 70, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("No exams added yet",
                      style:
                          TextStyle(fontSize: 17, color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Text("Tap + to add your first exam",
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (upcoming.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    const Icon(Icons.upcoming,
                        size: 16, color: Color(0xFF6549F3)),
                    const SizedBox(width: 6),
                    Text("Upcoming (${upcoming.length})",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF6549F3))),
                  ]),
                ),
                ...upcoming.map((e) => _buildExamCard(
                    e.key, Map<String, dynamic>.from(e.value as Map))),
              ],
              if (past.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Icon(Icons.history, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 6),
                    Text("Past (${past.length})",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey.shade500)),
                  ]),
                ),
                ...past.map((e) => _buildExamCard(
                    e.key, Map<String, dynamic>.from(e.value as Map))),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}
