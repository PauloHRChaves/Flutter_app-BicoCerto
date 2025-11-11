import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/location_suggestion.dart';

class LocationService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<List<LocationSuggestion>> searchAddress(String query) async {
    if (query.isEmpty || query.length < 3) {
      return [];
    }

    try {
      final uri = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': '1',
          'limit': '5',
          'countrycodes': 'br',
          'accept-language': 'pt-BR',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'BicoCerto/1.0 (Flutter App)',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: A requisição demorou muito para responder');
        },
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        if (decodedData is List) {
          final suggestions = decodedData
              .map((json) {
            try {
              return LocationSuggestion.fromJson(json);
            } catch (e) {
              return null;
            }
          })
              .whereType<LocationSuggestion>()
              .toList();

          return suggestions;
        } else {
          return [];
        }
      } else if (response.statusCode == 403) {
        throw Exception('Acesso negado pela API (403). Verifique as configurações.');
      } else {
        throw Exception('Erro ao buscar endereços: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  Future<LocationSuggestion?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse('$_baseUrl/reverse').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
          'addressdetails': '1',
          'accept-language': 'pt-BR',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'BicoCerto/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return LocationSuggestion.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}