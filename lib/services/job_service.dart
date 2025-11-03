import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bico_certo/models/job_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class JobService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }
    return {
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getUserReputation(String address) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/jobs/reputation?address=$address'),
        headers: headers,
      );
      print(response);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'reputation': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar reputação',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro: $e',
      };
    }
  }

  Future<List<Job>> getOpenJobs({String? category, String? searchTerm}) async {
    try {
      String url = '$baseUrl/jobs/open-jobs';

      List<String> queryParams = [];

      if (category != null && category.isNotEmpty) {
        queryParams.add('category=${Uri.encodeComponent(category)}');
      }

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(searchTerm)}');
      }

      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> jobsJson = data['data']['open_jobs'];
          return jobsJson.map((json) => Job.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Erro ao buscar jobs');
        }
      } else {
        throw Exception('Erro ao carregar jobs: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro no JobService.getOpenJobs: $e');
      rethrow;
    }
  }

  Future<List<Job>> getMyJobs() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/jobs/my-jobs'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> jobsJson = data['data']['jobs'];
          return jobsJson.map((json) => Job.fromJson(json)).toList();
        } else {
          throw Exception(data['message'] ?? 'Erro ao buscar meus jobs');
        }
      } else {
        throw Exception('Erro ao carregar jobs: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro no JobService.getMyJobs: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getJobProposals(String jobId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/jobs/job/$jobId/proposals_active'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> proposals = data['data']['proposals'];
          return proposals.cast<Map<String, dynamic>>();
        } else {
          throw Exception(data['message'] ?? 'Erro ao buscar propostas');
        }
      } else {
        throw Exception('Erro ao carregar propostas: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro no JobService.getJobProposals: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acceptProposal({
    required String proposalId,
    required String password,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/jobs/accept-proposal'),
        headers: headers,
        body: json.encode({
          'proposal_id': proposalId,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Proposta aceita com sucesso',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao aceitar proposta',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar com servidor: $e',
      };
    }
  }

  Future<Map<String, dynamic>> rejectProposal({
    required String proposalId,
    required String password,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/jobs/reject-proposal'),
        headers: headers,
        body: json.encode({
          'proposal_id': proposalId,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Proposta rejeitada',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao rejeitar proposta',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar com servidor: $e',
      };
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jobs/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> categoriesJson = data['data']['categories'];
          return categoriesJson.map((cat) => cat['name'] as String).toList();
        }
      }
      return [];
    } catch (e) {
      print('Erro ao buscar categorias: $e');
      return [];
    }
  }
}