import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../settings/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: controller.themeMode == ThemeMode.dark,
            onChanged: (v) => controller.updateThemeMode(
              v ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          DropdownButton<Locale>(
            value: controller.locale,
            onChanged: (l) => controller.updateLocale(l!),
            items: const [
              DropdownMenuItem(
                value: Locale('en'),
                child: Text('English'),
              ),
              DropdownMenuItem(
                value: Locale('ro'),
                child: Text('Română'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}