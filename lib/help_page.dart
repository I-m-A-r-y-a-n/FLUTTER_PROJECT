import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  void _showEmailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contact Support"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email us at:"),
            SizedBox(height: 8),
            Text(
              "support@companion.app",
              style: TextStyle(
                color: Color(0xFF6549F3),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text("We'll get back to you within 24 hours."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Email address copied: support@companion.app"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6549F3),
            ),
            child:
                const Text("Copy Email", style: TextStyle(color: Colors.white)),
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
        title: const Text("Help & Support",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            _sectionHeader(Icons.help_outline, "Frequently Asked Questions",
                const Color(0xFF6549F3)),
            const SizedBox(height: 12),
            _faqCard(
              "How do I add a task?",
              "Tap the + button on Home or Tasks page. Enter title, priority, and optional due date.",
            ),
            _faqCard(
              "What are routines?",
              "Routines are habits you want to track daily. Mark them as done each day to build streaks!",
            ),
            _faqCard(
              "How do I create a timetable?",
              "Go to Timetable from the drawer menu, tap +, and add your classes with time slots.",
            ),
            _faqCard(
              "How does exam tracking work?",
              "Add exams with dates and syllabus topics. Check off topics as you study them.",
            ),
            _faqCard(
              "Can I edit my profile?",
              "Yes! Go to Settings → Edit Name to update your display name.",
            ),

            const SizedBox(height: 24),

            // Contact Support
            _sectionHeader(
                Icons.support_agent, "Contact Support", Colors.green),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.email, size: 40, color: Color(0xFF6549F3)),
                  const SizedBox(height: 12),
                  const Text(
                    "Need help? Reach out to us!",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "support@companion.app",
                    style: TextStyle(fontSize: 14, color: Color(0xFF6549F3)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showEmailDialog(context),
                      icon: const Icon(Icons.email, size: 18),
                      label: const Text("Email Support"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6549F3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tips Section
            _sectionHeader(
                Icons.lightbulb_outline, "Pro Tips", Colors.amber.shade700),
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
                  _tipTile("🎯", "Set high priority tasks first",
                      "Tackle important tasks when you're most productive"),
                  const Divider(),
                  _tipTile("🔥", "Build streaks with routines",
                      "Mark routines daily to maintain your streak!"),
                  const Divider(),
                  _tipTile("📚", "Break down syllabus",
                      "Divide large subjects into smaller topics for better progress"),
                  const Divider(),
                  _tipTile("⏰", "Check timetable daily",
                      "Stay on top of your classes and assignments"),
                ],
              ),
            ),

            const SizedBox(height: 40),
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

  Widget _faqCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.question_answer,
                  size: 18, color: Color(0xFF6549F3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              answer,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipTile(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
