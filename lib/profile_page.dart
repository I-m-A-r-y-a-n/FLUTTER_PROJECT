import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = "...";
  String userEmail = "...";
  String joinDate = "...";
  bool isLoading = true;

  // Add these variables for stats
  int taskCount = 0;
  int routineCount = 0;
  int examCount = 0;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await DatabaseService.getUserProfile();
    final user = FirebaseAuth.instance.currentUser;

    // Get real counts from Firebase
    if (user != null) {
      try {
        final tasksSnapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}/tasks')
            .get();
        final routinesSnapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}/routines')
            .get();
        final examsSnapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}/exams')
            .get();

        if (mounted) {
          setState(() {
            taskCount = tasksSnapshot.exists && tasksSnapshot.value != null
                ? (tasksSnapshot.value as Map).length
                : 0;
            routineCount =
                routinesSnapshot.exists && routinesSnapshot.value != null
                    ? (routinesSnapshot.value as Map).length
                    : 0;
            examCount = examsSnapshot.exists && examsSnapshot.value != null
                ? (examsSnapshot.value as Map).length
                : 0;
          });
        }
      } catch (e) {
        print("Error fetching counts: $e");
      }
    }

    if (mounted) {
      setState(() {
        userName = profile?['name'] ?? user?.displayName ?? 'User';
        userEmail = profile?['email'] ?? user?.email ?? '';
        joinDate = profile?['createdAt'] != null
            ? _formatJoinDate(profile!['createdAt'])
            : 'Recently joined';
        isLoading = false;
      });
    }
  }

  String _formatJoinDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
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
      return 'Joined ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDE0EB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Profile",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6549F3), Color(0xFF4FC3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 55, color: Color(0xFF6549F3)),
                  ),
                  const SizedBox(height: 16),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  const SizedBox(height: 6),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      joinDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stats Section
            _sectionHeader(
                Icons.bar_chart, "Your Stats", const Color(0xFF6549F3)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCard(Icons.task_alt, "Tasks", taskCount.toString(),
                      Colors.green),
                  _statCard(Icons.repeat, "Routines", routineCount.toString(),
                      Colors.orange),
                  _statCard(Icons.school, "Exams", examCount.toString(),
                      Colors.deepOrange),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Section
            _sectionHeader(
                Icons.info_outline, "About You", Colors.grey.shade700),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoTile(Icons.email_outlined, "Email", userEmail),
                  const Divider(),
                  _infoTile(Icons.calendar_today, "Member Since", joinDate),
                  const Divider(),
                  _infoTile(
                      Icons.phone_android, "App Version", "Companion v1.0.0"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
