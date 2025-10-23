// lib/services/auth_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// TODA LOGICA DE COMUNICAÇÃO COM BACKEND

class AuthService {
  // Use o endereço do emulador Android para se conectar à sua máquina.
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';
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
      throw Exception(jsonResponse['detail'] ?? 'Erro desconhecido no registro.');
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
  // MÉTODOS CRIAÇÃO DE TRABALHO
  // ----------------------------------------------------------------------

  Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required String category,
    required String location,
    required String budget,
    required String deadline,
    required String password,
  }) async {

    // 1. Prepara o corpo (body) da requisição
    final Map<String, dynamic> jobData = {
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'max_budget_eth': budget,
      'deadline': deadline,
      'password': password,
    };

    // 2. Chama a função _securePost, que faz todo o trabalho:
    final response = await _securePost('jobs/create-open', body: jobData);

    // 3. Retorna a resposta, já tratada por _securePost
    return response;
  }

  // ----------------------------------------------------------------------
  // MÉTODOS DE PERFIL E WALLET
  // ----------------------------------------------------------------------
  
  // Obtém o perfil do usuário logado (GET /auth/me)
  Future<Map<String, dynamic>> getUserProfile() async {
    final responseData = await _secureGet('auth/me');
    return responseData['data'] as Map<String, dynamic>? ?? {}; 
  }

  // Obtém os detalhes da carteira (GET /wallet/my-wallet)
  Future<Map<String, dynamic>> getWalletDetails() async {
    try {
      final responseData = await _secureGet('wallet/my-wallet');
      
      // CASO A: API envia o status de "não tem carteira"
      if (responseData.containsKey('has_wallet')) {
        // Retorna {'has_wallet': false}
        return responseData;
      }
      
      // CASO B: API envia os detalhes da carteira (Carteira existe).
      final walletDataRaw = responseData['data'];
      
      if (walletDataRaw == null || walletDataRaw is! Map<String, dynamic>) {
        throw const FormatException("API retornou sucesso, mas houve falha ao enviar os dados.");
      }
      
      // Conversão segura após a verificação
      final Map<String, dynamic> walletData = walletDataRaw; 

      // Retorna os dados da carteira juntamente com o status de sucesso.
      return {
        'has_wallet': true,
        ...walletData,
      };

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

  // Importar Carteira
  Future<Map<String, dynamic>> importWalletFromPrivateKey({
    required String privateKey,
    required String password,
  }) async {
    final Map<String, dynamic> body = {
      "private_key": privateKey,
      "password": password,
      "force_replace": true,
    };
    // Usamos a sua função auxiliar _securePost que já trata token e headers
    final response = await _securePost('wallet/import/private-key', body: body);
    
    // retorna o "data" que contem wallet_id / adress
    return response['data'] as Map<String, dynamic>? ?? {};
  }
  
  // FUNÇÃO AUXILIAR PARA DELETE WALLET
  Future<Map<String, dynamic>> _secureDelete(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: body != null ? jsonEncode(body) : null,
    );

    if (response.statusCode == 200 || response.statusCode == 204) { // 204 também é sucesso para delete
      if (response.body.isEmpty) return {'success': true}; // Retorna sucesso se o corpo for vazio
      return json.decode(response.body);
    } else {
      try {
        final Map<String, dynamic> errorResponse = json.decode(response.body);
        if (errorResponse.containsKey('detail')) {
          throw Exception('Erro de API (${response.statusCode}): ${errorResponse['detail']}');
        }
      } catch (_) {}
      throw Exception('Falha na requisição DELETE. Status: ${response.statusCode}');
    }
  }

  // Deletar a carteira
  Future<void> deleteWallet({required String password}) async {
    await _secureDelete(
      'wallet/delete',
      body: {'password': password},
    );
  }

  // Metodo para transferir dinheiro(ETH)
  Future<Map<String, dynamic>> transferEth({
    required String password,
    required String toAddress,
    required double amount,
    required String note,
  }) async {
    final Map<String, dynamic> body = {
      'password': password,
      'to_address': toAddress,
      'amount_eth': amount,
      'note': note,
    };

    final response = await _securePost('wallet/transfer', body: body);

    return response;
  }

  // Metodo para buscar o historico de transações da wallet
  Future<List<Map<String, dynamic>>> getTransactions({int limit = 20}) async {
    final endpoint = 'wallet/transactions?limit=$limit';

    final responseData = await _secureGet(endpoint);

    final data = responseData['data'];
    if (data != null && data['transactions'] is List) {
      return List<Map<String, dynamic>>.from(data['transactions']);
    } else {
      return [];
    }
  }
}