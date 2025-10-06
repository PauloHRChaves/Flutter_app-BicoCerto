import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// TODA LOGICA DE COMUNICAÇÃO COM BACKEND - HAVERÁ MUDANÇAS

class AuthService {
  //final String baseUrl = 'http://127.0.0.1:8000'; // windows
  final String baseUrl = 'http://10.0.2.2:8000'; // android
  final _storage = const FlutterSecureStorage();

  // ----------------------------------------------------------------------
  // METODOS ESSENCIAIS (Conexões com Login e Registro)
  // ----------------------------------------------------------------------
  
  // Salva o token de acesso no armazenamento seguro do dispositivo
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  // Recupera o token de acesso
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  // Deleta o token
  Future<void> deleteToken() async {
    await _storage.delete(key: 'access_token');
  }
  
  // Verifica se o usuário tem um token válido (está autenticado)
  Future<bool> getAuthStatus() async {
    final token = await getToken();
    return token != null;
  }

  // Lógica de Registro
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
        'full_name': fullName,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      throw Exception('${jsonResponse['detail']}');
    }
  }

  // Lógica de Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required Map<String, dynamic> deviceInfo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'device_info': deviceInfo,
      }),
    );
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final String accessToken = responseBody['data']['access_token'];
      await saveToken(accessToken);
      return responseBody;
    } else {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      throw Exception('${jsonResponse['detail']}');
    }
  }

  // Simulação de informações de device - MOCK
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return {
      "device_id": "generic-test-device-id",
      "platform": "generic-test-platform",
      "model": "Flutter Test Model",
      "os_version": "1.0",
      "app_version": "1.0.0"
    };
  }

  // Logout
  Future<void> logout() async {
    final token = await getToken();
    
    if (token != null) {
      await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
        },
      );
    }
    await deleteToken();
  }


  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password/forgot'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'email': email}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      throw Exception('${jsonResponse['detail']}');
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String code,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/password/reset'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'reset_token': resetToken,
        'code': code,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      Map<String, dynamic> jsonResponse = json.decode(response.body);
      throw Exception('${jsonResponse['detail']}');
    }
  }
}