import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Configuration class for Chatbot API endpoints.
class ChatbotConfig {
  ChatbotConfig._();

  /// Default local development URL:
  /// - Environment flag: --dart-define=BACKEND_URL=http://...
  /// - Android Emulator: http://10.0.2.2:8000
  /// - iOS Simulator / Desktop / Web: http://127.0.0.1:8000
  /// - Physical device: set to your local machine IP (e.g., http://192.168.1.X:8000)
  static String get defaultBaseUrl {
    const envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
      if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        return 'http://127.0.0.1:8000';
      }
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  /// Active base URL (can be customized at runtime if needed).
  static String activeBaseUrl = defaultBaseUrl;
}

/// Response returned from the Python Chatbot API.
class ChatbotResponse {
  final String conversationId;
  final String answer;
  final String language;

  const ChatbotResponse({
    required this.conversationId,
    required this.answer,
    required this.language,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      conversationId: json['conversation_id']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      language: json['language']?.toString() ?? 'English',
    );
  }
}

/// Chat message model for the UI.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? language;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.language,
  });
}

/// Chatbot Service handling HTTP communication with the Python RAG backend.
class ChatbotService {
  final http.Client _client;
  String baseUrl;

  ChatbotService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ChatbotConfig.activeBaseUrl;

  /// Send a question to the NabhKrishi AI RAG backend.
  Future<ChatbotResponse> sendMessage({
    required String message,
    String? conversationId,
    String? userId,
  }) async {
    final uri = Uri.parse('$baseUrl/chat');
    final headers = {'Content-Type': 'application/json; charset=utf-8'};
    final payload = <String, dynamic>{
      'conversation_id': conversationId,
      'message': message,
    };
    if (userId != null) {
      payload['user_id'] = userId;
    }
    final body = jsonEncode(payload);

    debugPrint('Chatbot [REQUEST] URL: $uri (Method: POST)');
    debugPrint('Chatbot [REQUEST] Payload: $body');

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 120));

      debugPrint('Chatbot [RESPONSE] Status: ${response.statusCode}');
      debugPrint('Chatbot [RESPONSE] Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ChatbotResponse.fromJson(decoded);
      } else {
        String errDetail = 'Server error (${response.statusCode})';
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map && decoded.containsKey('detail')) {
            errDetail = decoded['detail'].toString();
          }
        } catch (_) {}
        debugPrint('Chatbot [ERROR] HTTP ${response.statusCode}: $errDetail');
        throw Exception(errDetail);
      }
    } on SocketException catch (e) {
      debugPrint('Chatbot [SOCKET ERROR] Cannot reach $baseUrl: $e');
      throw Exception("Sorry, I couldn't connect to NabhKrishi AI. Please check your backend connection.");
    } on TimeoutException catch (e) {
      debugPrint('Chatbot [TIMEOUT ERROR] Request to $uri timed out: $e');
      throw Exception("Server took too long to respond. Please try again.");
    } on FormatException catch (e) {
      debugPrint('Chatbot [FORMAT ERROR] Failed to parse server response: $e');
      throw Exception("Received an invalid response format from server. Please try again.");
    } catch (e) {
      debugPrint('Chatbot [UNEXPECTED ERROR]: $e');
      if (e is Exception) rethrow;
      throw Exception("Sorry, I couldn't connect to NabhKrishi AI. Please try again.");
    }
  }

  /// Check if the backend API is online.
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      debugPrint('Chatbot [HEALTH CHECK] Testing $uri ...');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      debugPrint('Chatbot [HEALTH CHECK] Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Chatbot [HEALTH CHECK ERROR]: $e');
      return false;
    }
  }
}

/// Riverpod provider for ChatbotService.
final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService();
});
