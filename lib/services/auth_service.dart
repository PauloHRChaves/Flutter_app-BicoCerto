import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// TODA LOGICA DE COMUNICAÇÃO COM BACKEND

class AuthService {
  final String baseUrl = 'https://e57963ea74ea.ngrok-free.app';
  final _storage = const FlutterSecureStorage();

  // ----------------------------------------------------------------------
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

  Future<void> saveUserId(String id) async {
    await _storage.write(key: 'user_id', value: id);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: 'user_id');
  }


  // ----------------------------------------------------------------------
  // lOGICA DE AUTENTICAÇÃO - LOGIN / REGISTER / LOGOUT / RESET PASS. / FORGOT PASS.
  // ----------------------------------------------------------------------
  
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
        'ngrok-skip-browser-warning': 'true',
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
      final String userId = responseBody['data']['user']['id'];
      await saveToken(accessToken);
      await saveUserId(userId);
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
    await deleteUserId();
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
      throw Exception('${jsonResponse['detail']}');
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
      throw Exception('${jsonResponse['detail']}');
    }
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
      // Retorna o corpo decodificado
      return json.decode(response.body);
    } else {
      // Retorna o status code para que a camada UI trate erros específicos (ex: 401, 404).
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
      throw Exception('Falha na requisição POST. Status: ${response.statusCode}');
    }
  }


  // ----------------------------------------------------------------------
  // NOVOS MÉTODOS WALLET (CORRIGIDOS)
  // ----------------------------------------------------------------------

  // Obtém os detalhes da carteira (GET /wallet/my-wallet)
  Future<Map<String, dynamic>> getWalletDetails() async {
    try {
      // O resultado de _secureGet já é Map<String, dynamic>
      final responseData = await _secureGet('wallet/my-wallet'); 
      
      // Se a resposta tiver a flag 'has_wallet', significa que é uma resposta de status (200 OK, mas sem carteira).
      if (responseData['has_wallet'] == false) {
         return responseData; // Retorna o Map que contém {"has_wallet": false}
      }
      
      // Se a carteira existir, os detalhes devem estar no campo 'data'.
      // Garante que retorna o Map<String, dynamic> ou um Map vazio {} se 'data' for nulo.
      return responseData['data'] as Map<String, dynamic>? ?? {};

    } catch (e) {
      rethrow; 
    }
  }

  // Cria uma nova carteira (POST /wallet/create)
  Future<Map<String, dynamic>> createWallet({required String password}) async {
    final Map<String, dynamic> body = {
      "password": password,
      "force_replace": false
    };
    final response = await _securePost('wallet/create', body: body);
    return response['data'] as Map<String, dynamic>? ?? {}; 
  }

  // Obtém o saldo da carteira (GET /wallet/balance)
  Future<Map<String, dynamic>> getBalance() async {
    final response = await _secureGet('wallet/balance');
    return response['data'] as Map<String, dynamic>? ?? {}; 
  }

}