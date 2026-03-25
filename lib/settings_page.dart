import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = "...";
  String userEmail = "...";
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final profile = await DatabaseService.getUserProfile();
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        userName = profile?['name'] ?? user?.displayName ?? 'User';
        userEmail = profile?['email'] ?? user?.email ?? '';
        isLoadingProfile = false;
      });
    }
  }

  // ─── EDIT NAME ───────────────────────────────────
  void showEditNameDialog() {
    final nameController = TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Your name",
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
              final newName = nameController.text.trim();
              if (newName.isEmpty) return;
              await DatabaseService.updateUserName(newName);
              await FirebaseAuth.instance.currentUser
                  ?.updateDisplayName(newName);
              setState(() => userName = newName);
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("Name updated!")));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6549F3)),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── CHANGE PASSWORD ─────────────────────────────
  void showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Change Password",
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Current password",
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "New password (min 6 chars)",
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Confirm new password",
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newController.text != confirmController.text) {
                        setDialogState(() => error = "Passwords do not match.");
                        return;
                      }
                      if (newController.text.length < 6) {
                        setDialogState(() =>
                            error = "Password must be at least 6 characters.");
                        return;
                      }
                      setDialogState(() {
                        isLoading = true;
                        error = null;
                      });
                      try {
                        final user = FirebaseAuth.instance.currentUser!;
                        // Re-authenticate first
                        final cred = EmailAuthProvider.credential(
                          email: user.email!,
                          password: currentController.text,
                        );
                        await user.reauthenticateWithCredential(cred);
                        await user.updatePassword(newController.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("Password changed successfully!")));
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          error = "Current password is incorrect.";
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6549F3)),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Update", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOGOUT ──────────────────────────────────────
  void confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
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
        title: const Text("Settings",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── PROFILE CARD ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6549F3), Color(0xFF4FC3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        isLoadingProfile
                            ? const SizedBox(
                                height: 16,
                                width: 100,
                                child: LinearProgressIndicator(
                                    backgroundColor: Colors.white24,
                                    color: Colors.white))
                            : Text(userName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(userEmail,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: showEditNameDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── ACCOUNT SECTION ───────────────────────
            _sectionLabel("Account"),
            const SizedBox(height: 8),
            _settingsCard([
              _settingsTile(
                icon: Icons.person_outline,
                title: "Edit Name",
                subtitle: userName,
                onTap: showEditNameDialog,
              ),
              _divider(),
              _settingsTile(
                icon: Icons.lock_outline,
                title: "Change Password",
                subtitle: "Update your password",
                onTap: showChangePasswordDialog,
              ),
            ]),

            const SizedBox(height: 20),

            // ── APPEARANCE SECTION ────────────────────
            _sectionLabel("Appearance"),
            const SizedBox(height: 8),
            _settingsCard([
              _settingsTileWithToggle(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                subtitle: "Coming soon",
                value: false,
                onChanged: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Dark mode coming in next update!")),
                  );
                },
              ),
            ]),

            const SizedBox(height: 20),

            // ── APP INFO SECTION ──────────────────────
            _sectionLabel("About"),
            const SizedBox(height: 8),
            _settingsCard([
              _settingsTile(
                icon: Icons.info_outline,
                title: "App Version",
                subtitle: "Companion v1.0.0",
                onTap: null,
                showArrow: false,
              ),
              _divider(),
              _settingsTile(
                icon: Icons.school_outlined,
                title: "Developer",
                subtitle: "Aryan • Roll No: 424106 • Section A",
                onTap: null,
                showArrow: false,
              ),
            ]),

            const SizedBox(height: 20),

            // ── LOGOUT ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: confirmLogout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
            letterSpacing: 1.2));
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6549F3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6549F3), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: showArrow
          ? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }

  Widget _settingsTileWithToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6549F3).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6549F3), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: const Color(0xFF6549F3),
      ),
    );
  }

  Widget _divider() {
    return Divider(
        height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200);
  }
}
