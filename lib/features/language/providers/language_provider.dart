import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageNotifier extends Notifier<String> {
  static const String _key = 'selected_language';

  @override
  String build() {
    // We return 'English' as default. SharedPreferences is loaded asynchronously,
    // so we can initialize synchronously and then load the saved setting if available.
    _loadLanguage();
    return 'English';
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(_key);
      if (lang != null && (lang == 'English' || lang == 'Hindi')) {
        state = lang;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String language) async {
    if (language != 'English' && language != 'Hindi') return;
    state = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, language);
    } catch (_) {}
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});
