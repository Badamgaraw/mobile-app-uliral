import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LocaleStorage {
  static const String _key = 'locale';

  static Future<void> saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  static Future<Locale?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      return Locale(code);
    }
    return null;
  }
}
