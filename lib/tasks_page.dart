import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Priority order for sorting
  int _priorityOrder(String p) {
    if (p == 'High') return 0;
    if (p == 'Medium') return 1;
    return 2;
  }

  Color _priorityColor(String p) {
    if (p == 'High') return Colors.red.shade400;
    if (p == 'Medium') return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── ADD TASK DIALOG ────────────────────────────
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
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
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
                      const Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        selectedDate == null
                            ? "Pick a date"
                            : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                        style: TextStyle(
                          color:
                              selectedDate == null ? Colors.grey : Colors.black,
                        ),
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
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  final dueDateStr = selectedDate == null
                      ? ''
                      : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
                  await DatabaseService.addTask(
                    titleController.text.trim(),
                    selectedPriority,
                    dueDateStr,
                  );
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

  // ─── DELETE CONFIRMATION ─────────────────────────
  void confirmDelete(String taskId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task"),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDE0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("My Tasks",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6549F3),
          labelColor: const Color(0xFF6549F3),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Pending"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTaskDialog,
        backgroundColor: const Color(0xFF6549F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: DatabaseService.getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value;
          final Map<String, dynamic> tasksMap =
              data != null ? Map<String, dynamic>.from(data as Map) : {};
          final allEntries = tasksMap.entries.toList();

          // Sort all by priority then due date
          allEntries.sort((a, b) {
            final ta = Map<String, dynamic>.from(a.value as Map);
            final tb = Map<String, dynamic>.from(b.value as Map);
            final priorityCompare = _priorityOrder(ta['priority'] ?? 'Low')
                .compareTo(_priorityOrder(tb['priority'] ?? 'Low'));
            if (priorityCompare != 0) return priorityCompare;
            final da = ta['dueDate'] ?? '';
            final db = tb['dueDate'] ?? '';
            if (da.isEmpty && db.isEmpty) return 0;
            if (da.isEmpty) return 1;
            if (db.isEmpty) return -1;
            return da.compareTo(db);
          });

          final pendingEntries = allEntries
              .where((e) =>
                  !(Map<String, dynamic>.from(e.value as Map)['isCompleted'] ??
                      false))
              .toList();
          final completedEntries = allEntries
              .where((e) =>
                  Map<String, dynamic>.from(e.value as Map)['isCompleted'] ??
                  false)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(allEntries),
              _buildTaskList(pendingEntries),
              _buildTaskList(completedEntries),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskList(List<MapEntry<String, dynamic>> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text("No tasks here",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final taskData = Map<String, dynamic>.from(entry.value as Map);
        final bool done = taskData['isCompleted'] ?? false;
        final String priority = taskData['priority'] ?? 'Low';
        final String dueDate = taskData['dueDate'] ?? '';
        final String title = taskData['title'] ?? '';

        // Check if overdue
        bool isOverdue = false;
        if (dueDate.isNotEmpty && !done) {
          final due = DateTime.tryParse(dueDate);
          if (due != null && due.isBefore(DateTime.now())) {
            isOverdue = true;
          }
        }

        return Dismissible(
          key: Key(entry.key),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            bool confirm = false;
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Delete Task"),
                content: Text('Delete "$title"?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      confirm = false;
                      Navigator.pop(ctx);
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      confirm = true;
                      Navigator.pop(ctx);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            return confirm;
          },
          onDismissed: (_) => DatabaseService.deleteTask(entry.key),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(color: _priorityColor(priority), width: 4),
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
                // Toggle complete
                GestureDetector(
                  onTap: () => DatabaseService.toggleTask(entry.key, done),
                  child: Icon(
                    done ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: done ? Colors.green : _priorityColor(priority),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: done ? Colors.grey : Colors.black,
                          decoration: done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _priorityColor(priority).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                fontSize: 11,
                                color: _priorityColor(priority),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (dueDate.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.calendar_today,
                              size: 11,
                              color: isOverdue ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isOverdue ? "Overdue: $dueDate" : "Due: $dueDate",
                              style: TextStyle(
                                fontSize: 11,
                                color: isOverdue ? Colors.red : Colors.grey,
                                fontWeight: isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button
                GestureDetector(
                  onTap: () => confirmDelete(entry.key, title),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
