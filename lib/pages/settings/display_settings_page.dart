import 'package:flutter/material.dart';

import '../../widgets/app_controllers.dart';

class DisplaySettingsPage extends StatelessWidget {
  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppControllers.of(context).settings;

    final tileBg = theme.brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : Colors.grey.shade300;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Display'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: AnimatedBuilder(
        animation: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: tileBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Dark mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Switch between light and dark theme.'),
                  value: settings.isDarkMode,
                  onChanged: (v) => settings.setDarkMode(v),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
