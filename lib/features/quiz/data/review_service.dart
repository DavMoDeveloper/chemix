import 'package:shared_preferences/shared_preferences.dart';

class ReviewService {
  static const _key = 'review_wrong_ids';

  Future<Set<String>> getWrongIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> addWrong(String elementId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    current.add(elementId);
    await prefs.setStringList(_key, current.toList());
  }

  Future<void> removeMany(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? []).toSet();
    current.removeAll(ids);
    await prefs.setStringList(_key, current.toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
