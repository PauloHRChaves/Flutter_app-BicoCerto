import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bico_certo/models/job_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class JobService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

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

      print('Fazendo requisição para: $url'); // Debug

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
          return categoriesJson
              .map((cat) => cat['name'] as String)
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Erro ao buscar categorias: $e');
      return [];
    }
  }
}