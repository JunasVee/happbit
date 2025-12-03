// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final auth = AuthService();
  final data = DataService(); // We'll create this next
  bool _loading = true;
  List<Map<String, dynamic>> habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _loading = true);

    final user = auth.currentUser;
    if (user == null) return;

    try {
      habits = await data.fetchHabits(user.id);
    } catch (e) {
      debugPrint("Error loading habits: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading habits: $e")));
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markDone(String habitId) async {
    final user = auth.currentUser;
    if (user == null) return;

    try {
      await data.markHabitDone(habitId, user.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Marked done")));
      await _loadHabits();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _signOut() async {
    await auth.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Signed out")));
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("HappBit"),
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == "logout") _signOut();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: "logout",
                child: Text("Sign out"),
              ),
            ],
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: navigate to "Create Habit" page later
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Coming soon")));
        },
        child: const Icon(Icons.add),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
              ? const Center(
                  child: Text(
                    "No habits yet.\nTap + to create one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHabits,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final h = habits[index];
                      final title = h['title'] ?? 'Untitled';
                      final desc = h['description'] ?? '';
                      final goal = h['goal'] ?? 1;

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(desc),
                          trailing: IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _markDone(h['id'] as String),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
