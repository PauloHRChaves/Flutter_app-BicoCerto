import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class PendingRatingService {
  static const _storage = FlutterSecureStorage();
  static const String _key = 'pending_client_rating';

  /// Salva uma avaliação pendente
  static Future<void> savePendingRating({
    required String jobId,
    required String clientName,
    required String jobTitle,
  }) async {
    final data = {
      'job_id': jobId,
      'client_name': clientName,
      'job_title': jobTitle,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _storage.write(key: _key, value: jsonEncode(data));
  }

  /// Recupera a avaliação pendente
  static Future<Map<String, dynamic>?> getPendingRating() async {
    try {
      final data = await _storage.read(key: _key);
      if (data == null) return null;
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }

  /// Remove a avaliação pendente
  static Future<void> clearPendingRating() async {
    await _storage.delete(key: _key);
  }

  /// Verifica se há avaliação pendente
  static Future<bool> hasPendingRating() async {
    final data = await getPendingRating();
    return data != null;
  }
}