import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static Future<bool> getIsFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isFirstTime') ?? true;
  }

  static Future<void> setIsFirstTime(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', value);
  }
}
// Dependência shared_preferences - guardar o valor de "isFirstTime" (para a welcome_page)