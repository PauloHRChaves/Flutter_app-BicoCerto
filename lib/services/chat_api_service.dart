import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatApiService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }
    return {
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Future<Map<String, dynamic>> createChatRoom({
    required String jobId,
    String? clientId,
    required String providerId,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/chat/room/create'),
      headers: headers,
      body: jsonEncode({
        'job_id': jobId,
        'client_id': clientId,
        'provider_id': providerId,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] as Map<String, dynamic>? ?? {};
    } else {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      throw Exception('${jsonResponse['detail']}');
    }
  }

  Future<List<dynamic>> getChatRooms({bool onlyActive = true}) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/chat/rooms?only_active=$onlyActive'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final rooms = responseBody['data']['rooms'] as List<dynamic>? ?? [];
        return rooms;
      } else {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        throw Exception('${jsonResponse['detail']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRoomMessages({
    required String roomId,
    int limit = 50,
    int offset = 0,
  }) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/chat/room/$roomId/messages?limit=$limit&offset=$offset'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] as Map<String, dynamic>? ?? {};
    } else {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      throw Exception('${jsonResponse['detail']}');
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String message,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? replyToId,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/chat/send'),
      headers: headers,
      body: jsonEncode({
        'room_id': roomId,
        'message': message,
        'message_type': messageType,
        'json_metadata': metadata,
        'reply_to_id': replyToId,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] as Map<String, dynamic>? ?? {};
    } else {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      throw Exception('${jsonResponse['detail']}');
    }
  }

  Future<void> markRoomAsRead(String roomId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/room/$roomId/mark-read'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        throw Exception('${jsonResponse['detail']}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<WebSocketChannel> connectWebSocket(String roomId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }

    final wsUrl = baseUrl.replaceFirst('https', 'wss').replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/chat/ws/$roomId?token=$token');

    return WebSocketChannel.connect(uri);
  }

  Future<WebSocketChannel> connectNotificationsWebSocket() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Usuário não autenticado');
    }

    String wsUrl = baseUrl;
    if (wsUrl.startsWith('https://')) {
      wsUrl = wsUrl.replaceFirst('https://', 'wss://');
    } else if (wsUrl.startsWith('http://')) {
      wsUrl = wsUrl.replaceFirst('http://', 'ws://');
    }

    final uri = Uri.parse('$wsUrl/chat/ws/notifications?token=$token');

    final channel = WebSocketChannel.connect(uri);

    return channel;
  }
}