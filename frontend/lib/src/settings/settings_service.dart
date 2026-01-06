import 'package:flutter/material.dart';

class SettingsService {
  Future<ThemeMode> themeMode() async => ThemeMode.system;
  Future<Locale> locale() async => const Locale('en');

  Future<void> updateThemeMode(ThemeMode mode) async {}
  Future<void> updateLocale(Locale locale) async {}
}