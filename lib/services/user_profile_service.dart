import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:bico_certo/services/auth_service.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  final AuthService _authService = AuthService();

  final Map<String, String?> _photoCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 2);

  Future<String?> getUserProfilePicture(String userId) async {
    if (_photoCache.containsKey(userId)) {
      final timestamp = _cacheTimestamps[userId];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return _photoCache[userId];
      }
    }

    try {
      final token = await _authService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/$userId/profile-picture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photoUrl = data['data']?['profile_pic_url'] as String?;

        _photoCache[userId] = photoUrl;
        _cacheTimestamps[userId] = DateTime.now();

        return photoUrl;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  void clearUserCache(String userId) {
    _photoCache.remove(userId);
    _cacheTimestamps.remove(userId);
  }

  void clearAllCache() {
    _photoCache.clear();
    _cacheTimestamps.clear();
  }
}