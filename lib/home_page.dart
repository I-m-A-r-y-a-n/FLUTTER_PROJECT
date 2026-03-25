import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';
import 'tasks_page.dart';
import 'routine_tracker_page.dart';
import 'timetable_page.dart';
import 'exams_page.dart';
import 'progress_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "...";

  int _priorityOrder(String p) {
    if (p == 'High') return 0;
    if (p == 'Medium') return 1;
    return 2;
  }

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<void> loadUserName() async {
    final profile = await DatabaseService.getUserProfile();
    if (profile != null && mounted) {
      setState(() => userName = profile['name'] ?? 'User');
    }
  }

  void showAddTaskDialog() {
    final titleController = TextEditingController();
    String selectedPriority = 'Medium';
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("New Task",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Task title",
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Priority",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: ['High', 'Medium', 'Low'].map((p) {
                  final isSelected = selectedPriority == p;
                  Color chipColor = p == 'High'
                      ? Colors.red
                      : p == 'Medium'
                          ? Colors.orange
                          : Colors.green;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedPriority = p),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? chipColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(p,
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
              const Text("Due Date (optional)",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null)
                    setDialogState(() => selectedDate = picked);
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
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        selectedDate == null
                            ? "Pick a date"
                            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        style: TextStyle(
                            color: selectedDate == null
                                ? Colors.grey
                                : Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  final dueDateStr = selectedDate == null
                      ? ''
                      : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                  await DatabaseService.addTask(titleController.text.trim(),
                      selectedPriority, dueDateStr);
                  Navigator.pop(context);
                }
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

  void confirmDelete(String taskId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task"),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteTask(taskId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String p) {
    if (p == 'High') return Colors.red.shade400;
    if (p == 'Medium') return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  void _goTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDE0EB),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF6549F3), Color(0xFF4FC3FF)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text("Hey, $userName 👋",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            drawerItem(Icons.task_alt, "My Tasks", () {
              Navigator.pop(context);
              _goTo(const TasksPage());
            }),
            drawerItem(Icons.repeat, "Routine Tracker", () {
              Navigator.pop(context);
              _goTo(const RoutineTrackerPage());
            }),
            drawerItem(Icons.calendar_month, "Timetable", () {
              Navigator.pop(context);
              _goTo(TimetablePage());
            }),
            drawerItem(Icons.school, "Exams", () {
              Navigator.pop(context);
              _goTo(ExamsPage());
            }),
            drawerItem(Icons.bar_chart, "Progress", () {
              Navigator.pop(context);
              _goTo(ProgressPage());
            }),
            const Divider(),
            drawerItem(Icons.person_outline, "Profile", () {
              Navigator.pop(context);
            }),
            drawerItem(Icons.settings, "Settings", () {
              Navigator.pop(context);
              _goTo(SettingsPage());
            }),
            drawerItem(Icons.help_outline, "Help", () {
              Navigator.pop(context);
            }),
            const Divider(),
            drawerItem(Icons.logout, "Logout", () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            }),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Companion", style: TextStyle(color: Colors.black)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Row(
              children: [
                Text(userName, style: const TextStyle(color: Colors.black)),
                const SizedBox(width: 10),
                const CircleAvatar(
                  backgroundColor: Color(0xFF6549F3),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DatabaseEvent>(
                stream: DatabaseService.getTasksStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data?.snapshot.value;
                  final Map<String, dynamic> tasksMap = data != null
                      ? Map<String, dynamic>.from(data as Map)
                      : {};
                  final allEntries = tasksMap.entries.toList();
                  final pendingEntries = allEntries.where((e) {
                    final t = Map<String, dynamic>.from(e.value as Map);
                    return !(t['isCompleted'] ?? false);
                  }).toList();

                  pendingEntries.sort((a, b) {
                    final ta = Map<String, dynamic>.from(a.value as Map);
                    final tb = Map<String, dynamic>.from(b.value as Map);
                    final pc = _priorityOrder(ta['priority'] ?? 'Low')
                        .compareTo(_priorityOrder(tb['priority'] ?? 'Low'));
                    if (pc != 0) return pc;
                    final da = ta['dueDate'] ?? '';
                    final db = tb['dueDate'] ?? '';
                    if (da.isEmpty && db.isEmpty) return 0;
                    if (da.isEmpty) return 1;
                    if (db.isEmpty) return -1;
                    return da.compareTo(db);
                  });

                  final topTasks = pendingEntries.take(4).toList();
                  final totalPending = pendingEntries.length;
                  final totalCompleted =
                      allEntries.length - pendingEntries.length;

                  if (allEntries.isEmpty) return _emptyTaskBanner();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Top Tasks ($totalPending pending)",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          if (totalCompleted > 0)
                            Text("$totalCompleted done ✓",
                                style: const TextStyle(
                                    color: Colors.green, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (topTasks.isEmpty)
                        _allDoneBanner()
                      else
                        ...topTasks.map((entry) {
                          final taskData =
                              Map<String, dynamic>.from(entry.value as Map);
                          return _taskCard(entry.key, taskData, false);
                        }),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _goTo(const TasksPage()),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF6549F3), width: 1.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("View All Tasks",
                                  style: TextStyle(
                                      color: Color(0xFF6549F3),
                                      fontWeight: FontWeight.bold)),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward,
                                  color: Color(0xFF6549F3), size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    optionTile(Icons.add_task, "Set Task", showAddTaskDialog),
                    optionTile(Icons.task_alt, "View All Tasks",
                        () => _goTo(const TasksPage())),
                    optionTile(Icons.repeat, "Routine Tracker",
                        () => _goTo(const RoutineTrackerPage())),
                    optionTile(Icons.calendar_month, "Timetable",
                        () => _goTo(TimetablePage())),
                    optionTile(Icons.school, "Exams", () => _goTo(ExamsPage())),
                    optionTile(Icons.bar_chart, "Progress",
                        () => _goTo(ProgressPage())),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskCard(String id, Map<String, dynamic> data, bool showCompleted) {
    final bool done = data['isCompleted'] ?? false;
    final String priority = data['priority'] ?? 'Low';
    final String dueDate = data['dueDate'] ?? '';
    final String title = data['title'] ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border(left: BorderSide(color: _priorityColor(priority), width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => DatabaseService.toggleTask(id, done),
            child: Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? Colors.green : _priorityColor(priority),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: done ? Colors.grey : Colors.black,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    )),
                if (dueDate.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 11, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("Due: $dueDate",
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _priorityColor(priority).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(priority,
                style: TextStyle(
                  fontSize: 11,
                  color: _priorityColor(priority),
                  fontWeight: FontWeight.bold,
                )),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => confirmDelete(id, title),
            child:
                const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _emptyTaskBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6549F3), Color(0xFF4FC3FF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text("No tasks yet — tap 'Set Task' to add one!",
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _allDoneBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Color(0xFF4FC3FF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text("🎉 All tasks completed! Great work!",
          style: TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget optionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF6549F3), size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  ListTile drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6549F3)),
      title: Text(title),
      onTap: onTap,
    );
  }
}
