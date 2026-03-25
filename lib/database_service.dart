import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  // ── PROFILE ─────────────────────────────────────
  static Future<void> createUserProfile(String name, String email) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance.ref('users/$uid/profile').set({
      'name': name,
      'email': email,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map?> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot =
        await FirebaseDatabase.instance.ref('users/$uid/profile').get();
    if (snapshot.exists)
      return Map<String, dynamic>.from(snapshot.value as Map);
    return null;
  }

  // ── TASKS ────────────────────────────────────────
  static Future<void> addTask(
      String title, String priority, String dueDate) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$uid/tasks').push();
    await ref.set({
      'title': title,
      'priority': priority,
      'dueDate': dueDate,
      'isCompleted': false,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Stream<DatabaseEvent> getTasksStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseDatabase.instance.ref('users/$uid/tasks').onValue;
  }

  static Future<void> toggleTask(String taskId, bool current) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance
        .ref('users/$uid/tasks/$taskId')
        .update({'isCompleted': !current});
  }

  static Future<void> deleteTask(String taskId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance.ref('users/$uid/tasks/$taskId').remove();
  }

  // ── ROUTINES ─────────────────────────────────────
  static Future<void> addRoutine(String type, String scheduledTime) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$uid/routines').push();
    await ref.set({
      'type': type,
      'scheduledTime': scheduledTime,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Stream<DatabaseEvent> getRoutinesStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseDatabase.instance.ref('users/$uid/routines').onValue;
  }

  static Future<void> markRoutineToday(String routineId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    await FirebaseDatabase.instance
        .ref('users/$uid/routines/$routineId/completedDates/$dateKey')
        .set(true);
  }

  static Future<void> deleteRoutine(String routineId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance
        .ref('users/$uid/routines/$routineId')
        .remove();
  }

  // ── TIMETABLE ────────────────────────────────────
  static Future<void> addTimetableEntry(
      String subject, String day, String startTime, String endTime) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$uid/timetable').push();
    await ref.set({
      'subject': subject,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Stream<DatabaseEvent> getTimetableStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseDatabase.instance.ref('users/$uid/timetable').onValue;
  }

  static Future<void> deleteTimetableEntry(String entryId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance
        .ref('users/$uid/timetable/$entryId')
        .remove();
  }

  // ── UPDATE NAME ───────────────────────────────
  static Future<void> updateUserName(String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance
        .ref("users/$uid/profile")
        .update({"name": name});
  }

  // ── EXAMS ────────────────────────────────────────
  static Future<void> addExam(String subject, String date, String startTime,
      String endTime, String notes) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$uid/exams').push();
    await ref.set({
      'subject': subject,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'notes': notes,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Stream<DatabaseEvent> getExamsStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseDatabase.instance.ref('users/$uid/exams').onValue;
  }

  static Future<void> deleteExam(String examId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance.ref('users/$uid/exams/$examId').remove();
  }

  // ── SYLLABUS TOPICS ──────────────────────────────
  static Future<void> addSyllabusTopic(String examId, String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance
        .ref('users/$uid/exams/$examId/syllabus')
        .push();
    await ref.set({'name': name, 'isDone': false});
  }

  static Future<void> toggleSyllabusTopic(
      String examId, String topicId, bool current) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance
        .ref('users/$uid/exams/$examId/syllabus/$topicId')
        .update({'isDone': !current});
  }

  static Future<void> deleteSyllabusTopic(String examId, String topicId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseDatabase.instance
        .ref('users/$uid/exams/$examId/syllabus/$topicId')
        .remove();
  }
}
