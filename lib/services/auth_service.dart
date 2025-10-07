// lib/services/auth_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// TODA LOGICA DE COMUNICAÇÃO COM BACKEND - HAVERÁ MUDANÇAS

class AuthService {
  // Use o endereço do emulador Android para se conectar à sua máquina.
  final String baseUrl = 'http://10.0.2.2:8000'; 
  final _storage = const FlutterSecureStorage();

  // ----------------------------------------------------------------------
<<<<<<< Updated upstream
  // FUNÇÕES AUXILIARES PROTEGIDAS (Para requisições que exigem Token)
=======
  // METODOS ESSENCIAIS - TOKEN
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
  
  // Verifica se o usuário tem um token válido
  Future<bool> getAuthStatus() async {
    final token = await getToken();
    return token != null;
  }

  // ----------------------------------------------------------------------
  // FUNÇÕES AUXILIARES PROTEGIDAS (Para requisições que exigem Token)
  // ----------------------------------------------------------------------

  // Função auxiliar para requisições GET protegidas por token.
  Future<Map<String, dynamic>> _secureGet(String endpoint) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: <String, String>{
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      try {
        final Map<String, dynamic> errorResponse = json.decode(response.body);
        if (errorResponse.containsKey('detail')) {
          throw Exception('Erro de API (${response.statusCode}): ${errorResponse['detail']}');
        }
      } catch (_) {}
      throw Exception('Falha na requisição GET. Status: ${response.statusCode}');
    }
  }

  // Função auxiliar para requisições POST protegidas por token.
  Future<Map<String, dynamic>> _securePost(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      try {
        final Map<String, dynamic> errorResponse = json.decode(response.body);
        if (errorResponse.containsKey('detail')) {
          throw Exception('Erro de API (${response.statusCode}): ${errorResponse['detail']}');
        }
      } catch (_) {}
      throw Exception('Falha na requisição POST. Status: ${response.statusCode}');
    }
  }

  // ----------------------------------------------------------------------
  // LOGICA DE AUTENTICAÇÃO - LOGIN / REGISTER / LOGOUT / RESET PASS. / FORGOT PASS.
  // ----------------------------------------------------------------------
  
  // Lógica de Registro (Omitida para brevidade)
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
      throw Exception(jsonResponse['detail'] ?? 'Erro desconhecido no registro.');
    }
  }

  // Lógica de Login (Omitida para brevidade)
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
      throw Exception(jsonResponse['detail'] ?? 'Erro desconhecido no login.');
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

  // Logout (Omitida para brevidade)
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

  // ESQUECEU A SENHA
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
      throw Exception(jsonResponse['detail'] ?? 'Falha ao solicitar redefinição.');
    }
  }

  // RESETAR SENHA
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
      throw Exception(jsonResponse['detail'] ?? 'Falha ao redefinir a senha.');
    }
  }

  // ----------------------------------------------------------------------
  // NOVOS MÉTODOS DE PERFIL E WALLET
>>>>>>> Stashed changes
  // ----------------------------------------------------------------------

  // NOVO MÉTODO: Obtém o perfil do usuário logado (GET /auth/me)
  Future<Map<String, dynamic>> getUserProfile() async {
    final responseData = await _secureGet('auth/me'); 
    
    // Retorna o objeto completo para a UI processar o nome, email, etc.
    return responseData['data'] as Map<String, dynamic>? ?? {}; 
  }
<<<<<<< Updated upstream

  // ----------------------------------------------------------------------
  // MÉTODOS ESSENCIAIS (Login, Registro, Logout)
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

  // Lógica de Registro (Omitida para brevidade)
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
      throw Exception('Falha no cadastro: ${response.statusCode}');
    }
  }

  // Lógica de Login (Omitida para brevidade)
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
      throw Exception('Falha no login: ${response.statusCode}');
    }
  }

  // Simulação de informações de device - MOCK (Omitida para brevidade)
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return {
      "device_id": "generic-test-device-id",
      "platform": "generic-test-platform",
      "model": "Flutter Test Model",
      "os_version": "1.0",
      "app_version": "1.0.0"
    };
  }

  // Logout (Omitida para brevidade)
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
      throw Exception('Falha ao solicitar redefinição: ${response.statusCode}');
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
      throw Exception('Falha ao redefinir a senha: ${response.statusCode}');
    }
  }

  // ----------------------------------------------------------------------
  // NOVOS MÉTODOS WALLET (CORRIGIDOS)
  // ----------------------------------------------------------------------

=======
  
>>>>>>> Stashed changes
  // 1. Obtém os detalhes da carteira (GET /wallet/my-wallet)
  Future<Map<String, dynamic>> getWalletDetails() async {
    try {
      final responseData = await _secureGet('wallet/my-wallet'); 
      
      // Se a resposta tiver a flag 'has_wallet', significa que é uma resposta de status (200 OK, mas sem carteira).
      if (responseData.containsKey('has_wallet')) {
         return responseData; // Retorna {"success": true, "has_wallet": false, ...}
      }
      
      // Se a carteira existir e os detalhes estiverem em 'data', retorna apenas os detalhes.
      return responseData['data'] as Map<String, dynamic>? ?? {};

    } catch (e) {
      rethrow; 
    }
  }

  // 2. Cria uma nova carteira (POST /wallet/create)
  Future<Map<String, dynamic>> createWallet({required String password}) async {
    final Map<String, dynamic> body = {
      "password": password,
      "force_replace": false
    };
    final response = await _securePost('wallet/create', body: body);
    return response['data'] as Map<String, dynamic>? ?? {}; 
  }

  // 3. Obtém o saldo da carteira (GET /wallet/balance)
  Future<Map<String, dynamic>> getBalance() async {
    final response = await _secureGet('wallet/balance');
    return response['data'] as Map<String, dynamic>? ?? {}; 
  }
}