import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';

class HabitTemplate {
  final String id;          // disimpan sebagai category di DB
  final String name;        // nama default habit
  final String subtitle;    // deskripsi pendek di kartu
  final IconData icon;
  final String unit;        // satuan default (min, ml, kcal, dll)
  final int defaultTarget;  // target default per hari

  const HabitTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.unit,
    required this.defaultTarget,
  });
}

// preset habit 
const List<HabitTemplate> kHabitTemplates = [
  HabitTemplate(
    id: 'cardio',
    name: 'Cardio',
    subtitle: 'Jogging, cycling, HIIT',
    icon: Icons.directions_run_rounded,
    unit: 'min',
    defaultTarget: 30,
  ),
  HabitTemplate(
    id: 'weights',
    name: 'Weight lifting',
    subtitle: 'Gym, strength training',
    icon: Icons.fitness_center_rounded,
    unit: 'session',
    defaultTarget: 1,
  ),
  HabitTemplate(
    id: 'learning',
    name: 'Learning',
    subtitle: 'Course, skill, language',
    icon: Icons.school_rounded,
    unit: 'min',
    defaultTarget: 30,
  ),
  HabitTemplate(
    id: 'reading',
    name: 'Reading',
    subtitle: 'Books, articles, notes',
    icon: Icons.menu_book_rounded,
    unit: 'pages',
    defaultTarget: 10,
  ),
  HabitTemplate(
    id: 'water',
    name: 'Water intake',
    subtitle: 'Drink enough water',
    icon: Icons.water_drop_rounded,
    unit: 'ml',
    defaultTarget: 2000,
  ),
  HabitTemplate(
    id: 'protein',
    name: 'Protein intake',
    subtitle: 'Hit daily protein',
    icon: Icons.egg_rounded,
    unit: 'g',
    defaultTarget: 100,
  ),
  HabitTemplate(
    id: 'micros',
    name: 'Micros & veggies',
    subtitle: 'Fruits & vegetables',
    icon: Icons.eco_rounded,
    unit: 'serving',
    defaultTarget: 3,
  ),
  HabitTemplate(
    id: 'supplements',
    name: 'Supplements',
    subtitle: 'Vitamin, creatine, etc.',
    icon: Icons.medication_rounded,
    unit: 'dose',
    defaultTarget: 1,
  ),
  HabitTemplate(
    id: 'calories',
    name: 'Daily calories',
    subtitle: 'Track kcal intake',
    icon: Icons.local_fire_department_rounded,
    unit: 'kcal',
    defaultTarget: 2000,
  ),
  HabitTemplate(
    id: 'sleep',
    name: 'Sleep',
    subtitle: 'Total hours of sleep',
    icon: Icons.bedtime_rounded,
    unit: 'hr',
    defaultTarget: 8,
  ),
  HabitTemplate(
    id: 'steps',
    name: 'Steps',
    subtitle: 'Daily steps',
    icon: Icons.directions_walk_rounded,
    unit: 'steps',
    defaultTarget: 8000,
  ),
  HabitTemplate(
    id: 'meditation',
    name: 'Meditation',
    subtitle: 'Mindfulness / breathing',
    icon: Icons.self_improvement_rounded,
    unit: 'min',
    defaultTarget: 10,
  ),
  HabitTemplate(
    id: 'stretching',
    name: 'Stretching',
    subtitle: 'Mobility & posture',
    icon: Icons.accessibility_new_rounded,
    unit: 'min',
    defaultTarget: 10,
  ),
  HabitTemplate(
    id: 'journaling',
    name: 'Journaling',
    subtitle: 'Reflect your day',
    icon: Icons.edit_rounded,
    unit: 'min',
    defaultTarget: 5,
  ),
];

/// Palet warna yang bisa dipilih user
const List<Color> kHabitColors = [
  Color(0xFF4F7DF9), // biru
  Color(0xFF33C07A), // hijau
  Color(0xFFFF6B6B), // merah
  Color(0xFFFFB347), // oranye
  Color(0xFF9B6BFF), // ungu
];

Color defaultColorForCategory(String cat) {
  switch (cat) {
    case 'water':
      return const Color(0xFF4F7DF9);
    case 'sleep':
      return const Color(0xFF33C07A);
    case 'calories':
      return const Color(0xFFFF6B6B);
    default:
      return const Color(0xFF4F7DF9);
  }
}

class AddHabitPage extends StatefulWidget {
  final AuthService auth;
  final DataService data;

  const AddHabitPage({
    super.key,
    required this.auth,
    required this.data,
  });

  @override
  State<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends State<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();

  HabitTemplate? _selectedTemplate;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetController;
  bool _saving = false;

  /// warna yang dipilih user (disimpan sebagai .value ke DB)
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = kHabitTemplates.first;
    _selectedColor = defaultColorForCategory(_selectedTemplate!.id);

    _titleController = TextEditingController(text: _selectedTemplate!.name);
    _descriptionController = TextEditingController();
    _targetController =
        TextEditingController(text: _selectedTemplate!.defaultTarget.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = _selectedTemplate?.unit ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'Create new habit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save habit',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose what you want to track',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick a habit type below. You can still rename it later.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kHabitTemplates.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3 / 2,
                  ),
                  itemBuilder: (context, index) {
                    final template = kHabitTemplates[index];
                    return _buildTemplateCard(template);
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Habit details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Habit name',
                    hintText: 'e.g. Morning cardio',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a habit name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add detail like time of day, notes, etc.',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Daily target',
                          hintText: _selectedTemplate!.defaultTarget.toString(),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a target';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Target must be > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 90,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unit',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // === COLOR PICKER ===
                const Text(
                  'Color',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final c in kHabitColors)
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedColor = c);
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c == _selectedColor
                                  ? Colors.black
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: c == _selectedColor
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  'You can adjust the target anytime from the habit settings.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(HabitTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTemplate = template;

          // auto-update title kalau user belum mengubah manual
          if (_titleController.text.isEmpty ||
              _titleController.text == _selectedTemplate!.name) {
            _titleController.text = template.name;
          }
          _targetController.text = template.defaultTarget.toString();

          // set default color berdasarkan kategori template
          _selectedColor = defaultColorForCategory(template.id);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1.2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                template.icon,
                size: 22,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              template.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a habit type')),
      );
      return;
    }

    final user = widget.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in')),
      );
      return;
    }

    final target = int.tryParse(_targetController.text.trim());

    setState(() => _saving = true);

    try {
      await widget.data.createHabit(
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedTemplate!.id,
        dailyTarget: target,
        unit: _selectedTemplate!.unit,
        color: _selectedColor.value, // ⬅️ kirim warna ke DB
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit created')),
      );
      Navigator.of(context).pop(true); // kembali ke home + trigger reload
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving habit: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
