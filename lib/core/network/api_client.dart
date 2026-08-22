import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

/// Custom network exceptions to handle backend failures cleanly.
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

class ApiClient {
  static const String baseUrl = 'https://nabhkrishi-backend.onrender.com';
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Helper to perform POST requests with JSON body and proper content headers.
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};
    final encodedBody = jsonEncode(body);

    developer.log('API POST Request to $url with body: $encodedBody');

    try {
      // 60-second timeout to handle Render cold-start behavior.
      final response = await _client
          .post(url, headers: headers, body: encodedBody)
          .timeout(const Duration(seconds: 60));

      developer.log('API POST Response from $url: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        String errMsg = 'Request failed with status: ${response.statusCode}';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('detail')) {
            errMsg = decoded['detail'].toString();
          }
        } catch (_) {}
        throw NetworkException(errMsg, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      developer.log('HTTP ClientException: $e');
      throw NetworkException('Network connection failed. Please check your internet connection.');
    } on StateError catch (e) {
      developer.log('StateError: $e');
      throw NetworkException('Unable to reach the server.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw NetworkException('Server took too long to respond. The system services may be warming up. Please try again.');
      }
      developer.log('Unexpected network error: $e');
      throw NetworkException('An unexpected network error occurred.');
    }
  }

  /// Helper to perform GET requests (like health checks).
  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    developer.log('API GET Request to $url');

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 15));
      developer.log('API GET Response from $url: ${response.statusCode} - ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw NetworkException('Server responded with error status: ${response.statusCode}', statusCode: response.statusCode);
      }
    } catch (e) {
      developer.log('Unexpected GET error: $e');
      throw NetworkException('Failed to connect to NabhKrishi services.');
    }
  }
}
