import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Logged in as:", style: Theme.of(context).textTheme.titleMedium),
            Text(user?.email ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Signed out")));
                }
              },
              child: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}
