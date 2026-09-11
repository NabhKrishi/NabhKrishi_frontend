import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../services/chatbot_service.dart';

/// Top prediction item from the Swin-T model.
class DiseasePredictionItem {
  final int classId;
  final String className;
  final double confidence;

  const DiseasePredictionItem({
    required this.classId,
    required this.className,
    required this.confidence,
  });

  factory DiseasePredictionItem.fromJson(Map<String, dynamic> json) {
    return DiseasePredictionItem(
      classId: (json['class_id'] as num?)?.toInt() ?? -1,
      className: json['class_name']?.toString() ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Model representing the PPO V3 reinforcement learning decision-support output.
class PpoDecision {
  final int actionId;
  final String actionName;
  final String? descriptionEn;
  final String? descriptionHi;

  const PpoDecision({
    required this.actionId,
    required this.actionName,
    this.descriptionEn,
    this.descriptionHi,
  });

  factory PpoDecision.fromJson(Map<String, dynamic> json) {
    return PpoDecision(
      actionId: (json['action_id'] as num?)?.toInt() ?? 0,
      actionName: json['action_name']?.toString() ?? 'Monitor',
      descriptionEn: json['description_en']?.toString(),
      descriptionHi: json['description_hi']?.toString(),
    );
  }

  /// Whether this decision recommends active guidance/review via the RAG chatbot
  bool get needsChatbotGuidance => actionId == 3 || actionId == 5;

  /// Whether this decision asks to recheck the leaf photo
  bool get isRecheck => actionId == 4;

  /// Localized farmer description
  String getLocalizedDescription(bool isHindi) {
    if (isHindi && descriptionHi != null && descriptionHi!.isNotEmpty) {
      return descriptionHi!;
    }
    return descriptionEn ?? _defaultDescription(actionId, isHindi);
  }

  static String _defaultDescription(int id, bool isHindi) {
    switch (id) {
      case 0:
        return isHindi ? 'अपनी फसल की सामान्य रूप से नियमित निगरानी जारी रखें।' : 'Continue monitoring your crop under standard management.';
      case 1:
        return isHindi ? 'रोग से बचाव हेतु प्रारंभिक फसल प्रबंधन की समीक्षा करें।' : 'Preventive crop-management review is recommended.';
      case 2:
        return isHindi ? 'सिंचाई अथवा पोषक तत्व प्रबंधन की समीक्षा आवश्यक है।' : 'Irrigation or nutrient management needs review.';
      case 3:
        return isHindi ? 'रोग प्रबंधन और सुरक्षात्मक उपायों की समीक्षा की सलाह दी जाती है।' : 'Disease-management review is recommended.';
      case 4:
        return isHindi ? 'सटीक परिणाम हेतु कृपया गेहूं पत्ती की एक और स्पष्ट फोटो लें।' : 'Please capture another clear image for rechecking.';
      case 5:
        return isHindi ? 'इस विषय पर नाभकृषि एआई से परामर्श करें।' : "Let's discuss this with NabhKrishi AI.";
      default:
        return isHindi ? 'फसल की निगरानी जारी रखें।' : 'Continue monitoring your crop.';
    }
  }

  /// Localized action title
  String getLocalizedActionName(bool isHindi) {
    if (!isHindi) return actionName;
    switch (actionId) {
      case 0:
        return 'फसल निगरानी (Monitor)';
      case 1:
        return 'बचाव प्रबंधन समीक्षा (Preventive)';
      case 2:
        return 'सिंचाई / पोषण समीक्षा (Irrigation/Nutrient)';
      case 3:
        return 'रोग प्रबंधन समीक्षा (Disease Management)';
      case 4:
        return 'पुनः जांच (Recheck Photo)';
      case 5:
        return 'नाभकृषि चैटबॉट से पूछें (Ask AI)';
      default:
        return actionName;
    }
  }
}

/// Model representing the disease prediction result for wheat leaves.
class CropDiseaseResult {
  final String diseaseName;
  final int classId;
  final double confidence;
  final String imagePath;
  final String description;
  final List<DiseasePredictionItem> topPredictions;
  final PpoDecision? decision;

  const CropDiseaseResult({
    required this.diseaseName,
    required this.confidence,
    required this.imagePath,
    required this.description,
    this.classId = -1,
    this.topPredictions = const [],
    this.decision,
  });

  bool get isHealthy => classId == 6 || diseaseName.toLowerCase().trim() == 'healthy';
  bool get isUncertain => confidence < 0.50;
  int get confidencePercent => (confidence * 100).toInt();

  /// Map English class names to Hindi representations for the farmer UI.
  static const Map<String, String> _hindiDiseaseMap = {
    'aphid': 'माहू / एफिड (Aphid)',
    'black rust': 'काला रतुआ / तना रतुआ (Black Rust)',
    'blast': 'गेहूं का झुलसा / ब्लास्ट (Blast)',
    'brown rust': 'भूरा रतुआ (Brown Rust)',
    'common root rot': 'जड़ सड़न (Common Root Rot)',
    'fusarium head blight': 'फ्यूजेरियम हेड ब्लाइट (Fusarium Head Blight)',
    'healthy': 'स्वस्थ पत्ती (Healthy)',
    'leaf blight': 'पत्ती झुलसा रोग (Leaf Blight)',
    'mildew': 'चूर्णिल आसिता / पाउडरी मिल्ड्यू (Mildew)',
    'mite': 'मकड़ी / माइट (Mite)',
    'septoria': 'सेप्टोरिया लीफ ब्लॉच (Septoria)',
    'smut': 'कंडुआ रोग / स्मट (Smut)',
    'stem fly': 'तना मक्खी (Stem Fly)',
    'tan spot': 'टैन स्पॉट (Tan Spot)',
    'yellow rust': 'पीला रतुआ (Yellow Rust)',
  };

  /// Returns localized disease name depending on language preference.
  String getLocalizedDiseaseName(bool isHindi) {
    if (!isHindi) return diseaseName;
    final key = diseaseName.toLowerCase().trim();
    return _hindiDiseaseMap[key] ?? diseaseName;
  }
}

/// Helper function to format raw snake/lowercase class names to Title Case.
String _formatTitle(String raw) {
  if (raw.isEmpty) return 'Unknown';
  return raw
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

/// Asynchronous service to send wheat leaf image to the FastAPI Swin-T backend.
Future<CropDiseaseResult> predictCropDisease(String imagePath) async {
  final file = File(imagePath);
  if (!await file.exists()) {
    throw Exception('Selected image file was not found on device.');
  }

  final fileSize = await file.length();
  if (fileSize == 0) {
    throw Exception('Selected image is empty. Please select a valid photo.');
  }
  if (fileSize > 15 * 1024 * 1024) {
    throw Exception('Image exceeds 15MB size limit. Please select a smaller photo.');
  }

  if (!ApiConstants.isConfigured &&
      !ChatbotConfig.activeBaseUrl.contains('http://10.') &&
      !ChatbotConfig.activeBaseUrl.contains('http://192.168.')) {
    throw Exception(
      'Laptop IP not configured. Please set your laptop Wi-Fi IPv4 address in '
      'lib/core/constants/api_constants.dart (e.g. const String apiBaseUrl = \'http://<YOUR_IP>:8000\';) '
      'or run with --dart-define=BACKEND_URL=http://<YOUR_IP>:8000',
    );
  }

  final targetUri = Uri.parse('${ApiConstants.resolvedBaseUrl}/predict');
  debugPrint('CropDisease [UPLOAD] Sending image to $targetUri');

  try {
    final request = http.MultipartRequest('POST', targetUri);
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamedResponse = await request.send().timeout(const Duration(seconds: 35));
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('CropDisease [RESPONSE] Status: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final prediction = (decoded['prediction'] as Map<String, dynamic>?) ?? {};
      final classId = (prediction['class_id'] as num?)?.toInt() ?? -1;
      final rawClassName = prediction['class_name']?.toString() ?? 'Unknown';
      final confidence = (prediction['confidence'] as num?)?.toDouble() ?? 0.0;

      final formattedName = _formatTitle(rawClassName);

      final topPredsList = (decoded['top_predictions'] as List<dynamic>?) ?? [];
      final topPredictions = topPredsList.map((item) {
        final m = item as Map<String, dynamic>;
        return DiseasePredictionItem(
          classId: (m['class_id'] as num?)?.toInt() ?? -1,
          className: _formatTitle(m['class_name']?.toString() ?? ''),
          confidence: (m['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      String defaultDescription;
      if (classId == 6 || formattedName.toLowerCase() == 'healthy') {
        defaultDescription = 'Wheat leaf appears healthy without prominent fungal or pest lesions.';
      } else {
        defaultDescription = 'Swin-T classification identified features consistent with $formattedName.';
      }

      PpoDecision? ppoDecision;
      if (decoded.containsKey('decision') && decoded['decision'] != null) {
        try {
          ppoDecision = PpoDecision.fromJson(decoded['decision'] as Map<String, dynamic>);
          debugPrint('CropDisease [PPO] Action: ${ppoDecision.actionId} (${ppoDecision.actionName})');
        } catch (e) {
          debugPrint('CropDisease [WARN] Failed to parse PPO decision: $e');
        }
      }

      return CropDiseaseResult(
        diseaseName: formattedName,
        classId: classId,
        confidence: confidence,
        imagePath: imagePath,
        description: defaultDescription,
        topPredictions: topPredictions,
        decision: ppoDecision,
      );
    } else {
      String errDetail = 'Server error (${response.statusCode})';
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded.containsKey('detail')) {
          errDetail = decoded['detail'].toString();
        }
      } catch (_) {}
      debugPrint('CropDisease [ERROR] HTTP ${response.statusCode}: $errDetail');
      throw Exception(errDetail);
    }
  } on SocketException catch (e) {
    debugPrint('CropDisease [WARN] Host $targetUri unreachable: $e');
    throw Exception(
      "Could not connect to NabhKrishi AI server at ${ApiConstants.resolvedBaseUrl}. "
      "Please ensure your phone and laptop are on the same Wi-Fi and FastAPI is running with --host 0.0.0.0.",
    );
  } on TimeoutException catch (e) {
    debugPrint('CropDisease [WARN] Host $targetUri timed out: $e');
    throw Exception("Image analysis timed out. The server may be processing or warming up. Please try again.");
  } catch (e) {
    debugPrint('CropDisease [UNEXPECTED ERROR]: $e');
    if (e is Exception) {
      rethrow;
    }
    throw Exception("Failed to analyze wheat leaf image. Please try again.");
  }
}
