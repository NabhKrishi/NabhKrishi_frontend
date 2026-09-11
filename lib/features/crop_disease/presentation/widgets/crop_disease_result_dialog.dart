import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../screens/nabhkrishi_chatbot_screen.dart';
import '../../services/crop_disease_service.dart';

class CropDiseaseResultDialog extends StatelessWidget {
  final CropDiseaseResult result;
  final bool isHindi;

  const CropDiseaseResultDialog({
    super.key,
    required this.result,
    required this.isHindi,
  });

  @override
  Widget build(BuildContext context) {
    final confidencePercent = result.confidencePercent;
    final isHealthy = result.isHealthy;
    final isUncertain = result.isUncertain;

    // Theme colors based on health/alert state
    final Color badgeColor = isHealthy
        ? const Color(0xFF6CE6B6)
        : (isUncertain ? const Color(0xFFFFD77B) : const Color(0xFFFF8B8B));

    final String badgeText = isHealthy
        ? (isHindi ? 'स्वस्थ' : 'Healthy')
        : (isUncertain
            ? (isHindi ? 'कम सटीकता' : 'Uncertain')
            : (isHindi ? 'सावधानी' : 'Alert'));

    final Color diseaseTitleColor = isHealthy
        ? const Color(0xFF6CE6B6)
        : const Color(0xFFFFD77B);

    return Dialog(
      backgroundColor: const Color(0xFF0C2A34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD77B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.biotech_rounded,
                      color: Color(0xFFFFD77B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHindi ? 'गेहूं रोग निदान (Swin-T)' : 'Wheat Disease Scan',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isHindi ? 'पत्ती विश्लेषण परिणाम' : 'Leaf analysis result',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Selected image display
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 190,
                  width: double.infinity,
                  color: Colors.black26,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (kIsWeb)
                        Image.network(
                          result.imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 40),
                          ),
                        )
                      else
                        Image.file(
                          File(result.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 40),
                          ),
                        ),
                      // Scanned overlay tag
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF6CE6B6), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'विश्लेषण संपन्न' : 'Image Analyzed',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Disease name card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF143844),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: (isHealthy ? const Color(0xFF6CE6B6) : const Color(0xFFFFD77B))
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'पहचाना गया परिणाम' : 'Detected Class',
                          style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.poppins(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.getLocalizedDiseaseName(isHindi),
                      style: GoogleFonts.poppins(
                        color: diseaseTitleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confidence Bar
                    Row(
                      children: [
                        Text(
                          '${isHindi ? 'सटीकता (Confidence)' : 'Confidence'}: ',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$confidencePercent%',
                          style: GoogleFonts.poppins(
                            color: badgeColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: result.confidence.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                      ),
                    ),

                    // Uncertainty warning banner if low confidence
                    if (isUncertain) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD77B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD77B).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFFFD77B), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isHindi
                                    ? 'अनिश्चित परिणाम — कृपया अधिक स्पष्ट और अच्छी रोशनी में गेहूं पत्ती की फोटो लें।'
                                    : 'Uncertain result — please capture a clearer wheat leaf image.',
                                style: GoogleFonts.poppins(color: const Color(0xFFFFD77B), fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Top predictions alternatives if available
                    if (result.topPredictions.length > 1) ...[
                      const SizedBox(height: 14),
                      Text(
                        isHindi ? 'अन्य संभावनाएं:' : 'Top Alternatives:',
                        style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: result.topPredictions.skip(1).map((item) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.className}: ${(item.confidence * 100).toInt()}%',
                              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // ============================================================
              // PPO V3 Reinforcement Learning Decision Support Card
              // ============================================================
              if (result.decision != null) ...[
                const SizedBox(height: 14),
                Builder(
                  builder: (context) {
                    final decision = result.decision!;
                    final int actionId = decision.actionId;

                    Color actionBadgeColor;
                    IconData actionIcon;
                    switch (actionId) {
                      case 0:
                        actionBadgeColor = const Color(0xFF6CE6B6);
                        actionIcon = Icons.visibility_rounded;
                        break;
                      case 1:
                        actionBadgeColor = const Color(0xFF4FC3F7);
                        actionIcon = Icons.shield_outlined;
                        break;
                      case 2:
                        actionBadgeColor = const Color(0xFF81D4FA);
                        actionIcon = Icons.water_drop_outlined;
                        break;
                      case 3:
                        actionBadgeColor = const Color(0xFFFF8B8B);
                        actionIcon = Icons.healing_rounded;
                        break;
                      case 4:
                        actionBadgeColor = const Color(0xFFFFD77B);
                        actionIcon = Icons.camera_alt_outlined;
                        break;
                      case 5:
                        actionBadgeColor = const Color(0xFFB39DDB);
                        actionIcon = Icons.chat_bubble_outline_rounded;
                        break;
                      default:
                        actionBadgeColor = const Color(0xFF6CE6B6);
                        actionIcon = Icons.eco_rounded;
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F323E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: actionBadgeColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.psychology_rounded,
                                    color: Color(0xFFFFD77B),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isHindi ? 'नाभकृषि निर्णय सहायता (PPO V3)' : 'NabhKrishi Decision Support',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFFFD77B),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: actionBadgeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Action $actionId',
                                  style: GoogleFonts.poppins(
                                    color: actionBadgeColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: actionBadgeColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  actionIcon,
                                  color: actionBadgeColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  decision.getLocalizedActionName(isHindi),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            decision.getLocalizedDescription(isHindi),
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 11.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 18),

              // Action button: Get Guidance / Recheck
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    (result.decision?.isRecheck ?? false)
                        ? Icons.camera_alt_rounded
                        : Icons.auto_awesome_rounded,
                    size: 18,
                  ),
                  label: Text(
                    (result.decision?.isRecheck ?? false)
                        ? (isHindi ? 'पुनः फोटो लें (Recheck)' : 'Recheck Photo')
                        : (isHindi ? 'सलाह प्राप्त करें (Get Guidance)' : 'Get Guidance'),
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (result.decision?.isRecheck ?? false)
                        ? const Color(0xFFFFD77B)
                        : const Color(0xFF6CE6B6),
                    foregroundColor: const Color(0xFF031A22),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();

                    if (result.decision?.isRecheck ?? false) {
                      // Return to camera / scanner for recheck
                      return;
                    }

                    final String promptText = isHealthy
                        ? (isHindi
                            ? 'मेरी गेहूं की फसल स्वस्थ है। फसल को रोगों से बचाने और अच्छी पैदावार के लिए क्या प्रारंभिक प्रबंधन उपाय करने चाहिए?'
                            : 'My wheat crop was detected as Healthy. What preventive care is recommended?')
                        : (isHindi
                            ? 'मेरी गेहूं की पत्ती में ${result.getLocalizedDiseaseName(true)} पाया गया है। इसके प्रबंधन, रोकथाम और उपचार के उपाय बताएं।'
                            : 'Provide verified guidance for ${result.diseaseName} in wheat.');

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NabhKrishiChatbotScreen(
                          isHindi: isHindi,
                          initialPrompt: promptText,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Close button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    foregroundColor: Colors.white70,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    isHindi ? 'बंद करें' : 'Close',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
