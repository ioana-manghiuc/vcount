import 'package:flutter/material.dart';
import 'settings_service.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._service);

  final SettingsService _service;

  ThemeMode themeMode = ThemeMode.system;
  Locale locale = const Locale('en');

  Future<void> loadSettings() async {
    themeMode = await _service.themeMode();
    locale = await _service.locale();
    notifyListeners();
  }

  void updateThemeMode(ThemeMode mode) {
    themeMode = mode;
    _service.updateThemeMode(mode);
    notifyListeners();
  }

  void updateLocale(Locale newLocale) {
    locale = newLocale;
    _service.updateLocale(newLocale);
    notifyListeners();
  }
}