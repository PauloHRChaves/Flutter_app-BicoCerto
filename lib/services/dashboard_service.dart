import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Service para gerenciar chamadas de API do Dashboard
class DashboardService {
  final _storage = const FlutterSecureStorage();
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  Future<void> downloadProviderPDF() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/provider/dashboard/export/pdf'),
        headers: headers
      );

      if (response.statusCode == 200) {
        await _saveAndOpenFile(response.bodyBytes, 'dashboard_prestador.pdf');
      } else {
        throw Exception('Erro ao baixar PDF');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> downloadProviderExcel() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/provider/dashboard/export/excel'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await _saveAndOpenFile(response.bodyBytes, 'dashboard_prestador.xlsx');
      } else {
        throw Exception('Erro ao baixar Excel');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> downloadClientPDF() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/client/dashboard/export/pdf'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await _saveAndOpenFile(response.bodyBytes, 'dashboard_cliente.pdf');
      } else {
        throw Exception('Erro ao baixar PDF');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> downloadClientExcel() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/client/dashboard/export/excel'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        await _saveAndOpenFile(response.bodyBytes, 'dashboard_cliente.xlsx');
      } else {
        throw Exception('Erro ao baixar Excel');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveAndOpenFile(List<int> bytes, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  }

  /// Obtém os headers com autenticação
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.isEmpty) {
      throw DashboardException('Token não encontrado. Faça login novamente');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// ════════════════════════════════════════════════════════
  /// PROVIDER DASHBOARD
  /// ════════════════════════════════════════════════════════

  /// Busca dados completos do dashboard do prestador
  Future<Map<String, dynamic>> getProviderDashboard() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/provider/dashboard'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar dashboard');
        }
      } else if (response.statusCode == 401) {
        throw DashboardException('Não autorizado. Faça login novamente');
      } else if (response.statusCode == 404) {
        throw DashboardException('Recurso não encontrado');
      } else if (response.statusCode == 500) {
        throw DashboardException('Erro no servidor');
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) {
        rethrow;
      }
      throw DashboardException('Erro ao carregar dashboard: $e');
    }
  }

  /// Busca apenas estatísticas rápidas do prestador
  Future<Map<String, dynamic>> getProviderQuickStats() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/provider/dashboard/quick-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar estatísticas');
        }
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) rethrow;
      throw DashboardException('Erro ao carregar estatísticas: $e');
    }
  }

  /// Busca ganhos mensais do prestador
  Future<List<Map<String, dynamic>>> getProviderMonthlyEarnings({
    int months = 6,
  }) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/api/provider/dashboard/earnings')
          .replace(queryParameters: {'months': months.toString()});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> earnings = data['data'];
          return earnings.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar ganhos');
        }
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) rethrow;
      throw DashboardException('Erro ao carregar ganhos: $e');
    }
  }

  /// Busca performance por categoria do prestador
  Future<List<Map<String, dynamic>>> getProviderCategoryPerformance() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/provider/dashboard/categories'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> categories = data['data'];
          return categories.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar categorias');
        }
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) rethrow;
      throw DashboardException('Erro ao carregar categorias: $e');
    }
  }

  /// ════════════════════════════════════════════════════════
  /// CLIENT DASHBOARD
  /// ════════════════════════════════════════════════════════

  /// Busca dados completos do dashboard do cliente
  Future<Map<String, dynamic>> getClientDashboard() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/client/dashboard'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar dashboard');
        }
      } else if (response.statusCode == 401) {
        throw DashboardException('Não autorizado. Faça login novamente');
      } else if (response.statusCode == 404) {
        throw DashboardException('Recurso não encontrado');
      } else if (response.statusCode == 500) {
        throw DashboardException('Erro no servidor');
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) {
        rethrow;
      }
      throw DashboardException('Erro ao carregar dashboard: $e');
    }
  }

  /// Busca apenas estatísticas rápidas do cliente
  Future<Map<String, dynamic>> getClientQuickStats() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/api/client/dashboard/quick-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar estatísticas');
        }
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) rethrow;
      throw DashboardException('Erro ao carregar estatísticas: $e');
    }
  }

  /// Busca gastos mensais do cliente
  Future<List<Map<String, dynamic>>> getClientMonthlySpending({
    int months = 6,
  }) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/api/client/dashboard/spending')
          .replace(queryParameters: {'months': months.toString()});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> spending = data['data'];
          return spending.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar gastos');
        }
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) rethrow;
      throw DashboardException('Erro ao carregar gastos: $e');
    }
  }

  /// Busca jobs recentes do cliente
  Future<List<Map<String, dynamic>>> getClientRecentJobs({
    int limit = 5,
  }) async {
    try {
      final headers = await _getHeaders();

      final uri = Uri.parse('$baseUrl/api/client/dashboard/recent-jobs')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> jobs = data['data'];
          return jobs.map((e) => e as Map<String, dynamic>).toList();
        } else {
          throw DashboardException(data['message'] ?? 'Erro ao carregar jobs');
        }
      } else {
        throw DashboardException('Erro: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DashboardException) rethrow;
      throw DashboardException('Erro ao carregar jobs: $e');
    }
  }
}

/// Exceção personalizada para erros do Dashboard
class DashboardException implements Exception {
  final String message;

  DashboardException(this.message);

  @override
  String toString() => message;
}