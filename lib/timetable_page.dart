import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> shortDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  String get todayName => days[DateTime.now().weekday - 1];

  final List<Color> subjectColors = [
    Color(0xFF6549F3),
    Colors.orange,
    Colors.green,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.red,
    Colors.cyan,
  ];
  final Map<String, Color> _subjectColorMap = {};
  int _colorIndex = 0;

  Color _getSubjectColor(String subject) {
    if (!_subjectColorMap.containsKey(subject)) {
      _subjectColorMap[subject] =
          subjectColors[_colorIndex % subjectColors.length];
      _colorIndex++;
    }
    return _subjectColorMap[subject]!;
  }

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1;
    _tabController =
        TabController(length: 7, vsync: this, initialIndex: todayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void showAddEntryDialog({String? preselectedDay}) {
    final subjectController = TextEditingController();
    String selectedDay = preselectedDay ?? todayName;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Class",
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
                    hintText: "Subject name (e.g. Math, Physics)",
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Day",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: days.map((day) {
                    final isSelected = selectedDay == day;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedDay = day),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6549F3)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(day.substring(0, 3),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            )),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text("Start Time",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 8, minute: 0),
                    );
                    if (picked != null)
                      setDialogState(() => startTime = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        startTime == null
                            ? "Pick start time"
                            : startTime!.format(context),
                        style: TextStyle(
                            color:
                                startTime == null ? Colors.grey : Colors.black),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("End Time",
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked != null) setDialogState(() => endTime = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        endTime == null
                            ? "Pick end time"
                            : endTime!.format(context),
                        style: TextStyle(
                            color:
                                endTime == null ? Colors.grey : Colors.black),
                      ),
                    ]),
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please enter a subject name")));
                  return;
                }
                if (startTime == null || endTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Please pick start and end time")));
                  return;
                }
                await DatabaseService.addTimetableEntry(
                  subjectController.text.trim(),
                  selectedDay,
                  startTime!.format(context),
                  endTime!.format(context),
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

  void confirmDeleteClass(String entryId, String subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Class"),
        content: Text('Remove "$subject" from timetable?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteTimetableEntry(entryId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, dynamic>> _sortByTime(
      List<MapEntry<String, dynamic>> entries) {
    entries.sort((a, b) {
      final ta = Map<String, dynamic>.from(a.value as Map);
      final tb = Map<String, dynamic>.from(b.value as Map);
      return (ta['startTime'] ?? '').compareTo(tb['startTime'] ?? '');
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDE0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Timetable",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF6549F3),
          labelColor: const Color(0xFF6549F3),
          unselectedLabelColor: Colors.grey,
          tabAlignment: TabAlignment.start,
          tabs: List.generate(7, (i) {
            final isToday = days[i] == todayName;
            return Tab(
              child: Row(
                children: [
                  Text(shortDays[i],
                      style: TextStyle(
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      )),
                  if (isToday) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6549F3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            showAddEntryDialog(preselectedDay: days[_tabController.index]),
        backgroundColor: const Color(0xFF6549F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: DatabaseService.getTimetableStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.snapshot.value;
          final Map<String, dynamic> timetableMap =
              data != null ? Map<String, dynamic>.from(data as Map) : {};
          final allEntries = timetableMap.entries.toList();

          return TabBarView(
            controller: _tabController,
            children: List.generate(7, (i) {
              final day = days[i];
              final dayEntries = allEntries.where((e) {
                final d = Map<String, dynamic>.from(e.value as Map);
                return d['day'] == day;
              }).toList();
              final sorted = _sortByTime(dayEntries);

              if (sorted.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today,
                          size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text("No classes on $day",
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 16)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => showAddEntryDialog(preselectedDay: day),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6549F3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("+ Add Class",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final entry = sorted[index];
                  final d = Map<String, dynamic>.from(entry.value as Map);
                  final subject = d['subject'] ?? '';
                  final startTime = d['startTime'] ?? '';
                  final endTime = d['endTime'] ?? '';
                  final color = _getSubjectColor(subject);

                  bool isNow = false;
                  try {
                    if (day == todayName &&
                        startTime.isNotEmpty &&
                        endTime.isNotEmpty) {
                      final now = TimeOfDay.now();
                      final nowMin = now.hour * 60 + now.minute;
                      int parseMinutes(String t) {
                        final parts = t
                            .replaceAll(' AM', '')
                            .replaceAll(' PM', '')
                            .split(':');
                        int h = int.parse(parts[0]);
                        final m = int.parse(parts[1].split(' ')[0]);
                        if (t.contains('PM') && h != 12) h += 12;
                        if (t.contains('AM') && h == 12) h = 0;
                        return h * 60 + m;
                      }

                      isNow = nowMin >= parseMinutes(startTime) &&
                          nowMin <= parseMinutes(endTime);
                    }
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(left: BorderSide(color: color, width: 4)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(startTime,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: color)),
                              Container(
                                  width: 1,
                                  height: 16,
                                  color: Colors.grey.shade300,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 3)),
                              Text(endTime,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(subject,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold)),
                                  if (isNow) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: const Text("NOW",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.access_time,
                                      size: 12, color: color),
                                  const SizedBox(width: 4),
                                  Text("$startTime – $endTime",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600)),
                                ]),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => confirmDeleteClass(entry.key, subject),
                            child: const Icon(Icons.delete_outline,
                                color: Colors.grey, size: 20),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}
