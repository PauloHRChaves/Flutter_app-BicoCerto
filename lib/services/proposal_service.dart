import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProposalService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }
    return {
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  Future<Map<String, dynamic>> submitProposal({
    required String jobId,
    required String description,
    required double amountEth,
    required int estimatedTimeDays,
    required String password,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/jobs/submit-proposal'),
        headers: headers,
        body: json.encode({
          'job_id': jobId,
          'description': description,
          'amount_eth': amountEth,
          'estimated_time_days': estimatedTimeDays,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Proposta enviada com sucesso',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao enviar proposta',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar com servidor: $e',
      };
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
          final List<dynamic> proposals = data['data']['proposals'] ?? [];
          return proposals.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getMyProposals() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/jobs/my-proposals'),
        headers: headers,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['success'] == true) {
          if (data['data'] != null) {
            final proposals = data['data']['proposals'];
            return {
              'success': true,
              'proposals': proposals ?? [],
              'total': data['data']['total'] ?? 0,
              'pending': data['data']['pending'] ?? 0,
              'accepted': data['data']['accepted'] ?? 0,
            };
          } else {
            return {
              'success': false,
              'message': 'Resposta sem dados',
              'proposals': [],
            };
          }
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Erro desconhecido',
            'proposals': [],
          };
        }
      } else {
        return {
          'success': false,
          'message':
          data['message'] ?? 'Erro ao buscar propostas (Status: ${response.statusCode})',
          'proposals': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar com servidor: $e',
        'proposals': [],
      };
    }
  }

  Future<Map<String, dynamic>> cancelProposal({
    required String proposalId,
    required String password,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/jobs/cancel-proposal'),
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
          'message': data['message'] ?? 'Proposta cancelada com sucesso',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao cancelar proposta',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao conectar com servidor: $e',
      };
    }
  }

  Future<Map<String, dynamic>?> getMyProposalForJob(String jobId) async {
    try {
      final result = await getMyProposals();

      if (result['success'] == true) {
        final List<dynamic> proposals = result['proposals'] ?? [];

        for (var proposal in proposals) {
          if (proposal['job_id'] == jobId) {
            final status = proposal['status']?.toString().toLowerCase() ?? '';

            if (status == 'pending' || status == 'accepted') {
              return proposal;
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}