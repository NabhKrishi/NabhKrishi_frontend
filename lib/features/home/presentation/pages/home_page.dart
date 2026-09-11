import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../../core/localization/app_localizations.dart';
import '../../../language/providers/language_provider.dart';
import '../../../location/presentation/widgets/farm_map_widget.dart';
import '../../../location/providers/location_provider.dart';
import '../../../location/models/location_model.dart';
import '../../../irrigation/models/irrigation_models.dart';
import '../../../irrigation/providers/irrigation_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/farm_model.dart';
import '../../../../services/firestore_service.dart';
import '../../../../screens/nabhkrishi_chatbot_screen.dart';
import '../../../crop_disease/presentation/widgets/crop_disease_result_dialog.dart';
import '../../../crop_disease/services/crop_disease_service.dart';
import 'analytics_page.dart';

class HomePage extends ConsumerStatefulWidget {
  final String language;
  final String farmerName;

  /// How many consecutive days the farmer has opened the app —
  /// a small, honest sense of "we've been at this together for a while."
  final int streakDays;

  const HomePage({
    super.key,
    required this.language,
    this.farmerName = '',
    this.streakDays = 1,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  int selectedIndex = 0;

  // Gentle up/down drift on the hero card — makes it feel like it's breathing.
  late final AnimationController _floatController;

  // Drives the staggered "wake up" of the dashboard on first load.
  late final AnimationController _entranceController;

  // Draws the health ring in rather than snapping it straight to 82%.
  late final AnimationController _ringController;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _ringController.forward();
    });

    // Initialize the language
    Future.microtask(() {
      ref.read(languageProvider.notifier).setLanguage(widget.language);
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _entranceController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';



    return Scaffold(
      backgroundColor: const Color(0xFF031A22),
      extendBody: true,
      body: Stack(
        children: [
          const _Background(),

          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: selectedIndex,
              children: [
                _Dashboard(
                  farmerName: widget.farmerName,
                  streakDays: widget.streakDays,
                  floatController: _floatController,
                  entranceController: _entranceController,
                  ringController: _ringController,
                ),
                AnalyticsPage(isHindi: isHindi),
                _SimplePage(
                  isHindi: isHindi,
                  icon: Icons.agriculture_rounded,
                  title: isHindi ? 'मेरा खेत' : 'My farm',
                  subtitle: isHindi
                      ? 'अपनी फसल और खेत देखें।'
                      : 'Keep an eye on your crops and fields.',
                ),
                _SimplePage(
                  isHindi: isHindi,
                  icon: Icons.person_outline_rounded,
                  title: isHindi ? 'प्रोफ़ाइल' : 'Your profile',
                  subtitle: isHindi
                      ? 'आपकी NabhKrishi प्रोफ़ाइल।'
                      : 'Your NabhKrishi profile.',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        selectedIndex: selectedIndex,
        isHindi: isHindi,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          setState(() {
            selectedIndex = value;
          });
        },
      ),
    );
  }
}

// ============================================================================
// REVEAL — shared stagger helper. Nothing on the dashboard just "appears";
// it settles in, one breath after another.
// ============================================================================

class _Reveal extends StatelessWidget {
  final Animation<double> controller;
  final double start;
  final Widget child;

  const _Reveal({
    required this.controller,
    required this.start,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final end = (start + 0.45).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 22),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ============================================================================
// PRESSABLE — tiny scale-down-on-touch + haptic, so tapping anything
// feels like it responds to *you*, not just registers a click.
// ============================================================================

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double downScale;

  const _Pressable({
    required this.child,
    required this.onTap,
    this.downScale = 0.96,
  });

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _scale = widget.downScale),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) {
        setState(() => _scale = 1);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
class _Dashboard extends ConsumerWidget {
  final String farmerName;
  final int streakDays;
  final AnimationController floatController;
  final AnimationController entranceController;
  final AnimationController ringController;

  const _Dashboard({
    required this.farmerName,
    required this.streakDays,
    required this.floatController,
    required this.entranceController,
    required this.ringController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';
    final confirmedLoc = ref.watch(confirmedLocationProvider);
    final centroid = confirmedLoc.centroid;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _Reveal(controller: entranceController, start: 0.0, child: const _TopBar()),

              const SizedBox(height: 20),

              _Reveal(
                controller: entranceController,
                start: 0.03,
                child: _StreakRibbon(streakDays: streakDays),
              ),

              const SizedBox(height: 22),

              _Reveal(
                controller: entranceController,
                start: 0.06,
                child: _Greeting(farmerName: farmerName),
              ),

              const SizedBox(height: 22),

              // Farm Selection Map Card
              _Reveal(
                controller: entranceController,
                start: 0.1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      title: context.translate('select_farm_area', currentLanguage),
                      subtitle: isHindi
                          ? 'मानचित्र पर टैप करके सीमा बनाएं या खेत खोजें'
                          : 'Draw boundary, search manually, or use your location',
                    ),
                    const SizedBox(height: 12),
                    FarmMapWidget(
                      onLocationConfirmed: () {
                        // Confirm Farm Location: copies state from active locationProvider to confirmedLocationProvider
                        final activeLoc = ref.read(locationProvider);
                        ref.read(confirmedLocationProvider.notifier).state = activeLoc.copyWith(isDrawing: false);
                        ref.read(locationProvider.notifier).toggleDrawing(false);
                      },
                    ),
                    const _ManualCoordinatesInput(),
                    const _FarmLocationDetailsCard(),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Dynamic Recommendation Section (rebuilds separately from map when state updates)
              _RecommendationSection(
                centroid: centroid,
                floatController: floatController,
                entranceController: entranceController,
                ringController: ringController,
              ),

              const SizedBox(height: 30),

              _Reveal(
                controller: entranceController,
                start: 0.42,
                child: _SectionTitle(
                  title: isHindi ? 'कुछ चाहिए?' : 'Need something?',
                  subtitle: isHindi ? 'NabhKrishi यहाँ है।' : 'NabhKrishi is here.',
                ),
              ),

              const SizedBox(height: 14),

              _Reveal(
                controller: entranceController,
                start: 0.45,
                child: const _HumanActions(),
              ),

              const SizedBox(height: 30),

              _Reveal(
                controller: entranceController,
                start: 0.48,
                child: _NabhMessage(),
              ),

              const SizedBox(height: 20),

              _Reveal(
                controller: entranceController,
                start: 0.52,
                child: const _FeedbackCard(),
              ),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    return Row(
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFA8F6D5), Color(0xFF39C793)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF56E2AF).withValues(alpha: 0.18),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: const Icon(Icons.eco_rounded, color: Color(0xFF07372B), size: 23),
            ),
            const SizedBox(width: 11),
            Text(
              'NabhKrishi',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Language Toggle EN | हिंदी
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(languageProvider.notifier).setLanguage('English');
                },
                child: Text(
                  'EN',
                  style: GoogleFonts.poppins(
                    color: currentLanguage == 'English' ? const Color(0xFF70E8B9) : Colors.white30,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('|', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(languageProvider.notifier).setLanguage('Hindi');
                },
                child: Text(
                  'हिंदी',
                  style: GoogleFonts.poppins(
                    color: currentLanguage == 'Hindi' ? const Color(0xFF70E8B9) : Colors.white30,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _SmallButton(icon: Icons.notifications_none_rounded, dot: true, onTap: () {}),
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final bool dot;
  final VoidCallback onTap;

  const _SmallButton({required this.icon, required this.onTap, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      downScale: 0.9,
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.045),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
            ),
            child: Icon(icon, color: Colors.white60, size: 21),
          ),
          if (dot)
            Positioned(
              top: 9,
              right: 9,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFF72E9BF), shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// STREAK RIBBON — the "we've been doing this together" touch.
// ============================================================================

// ============================================================================
// STREAK RIBBON
// ============================================================================

class _StreakRibbon extends ConsumerWidget {
  final int streakDays;

  const _StreakRibbon({required this.streakDays});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';
    final label = isHindi
        ? 'साथ में $streakDays दिन 🌱'
        : '$streakDays days together 🌱';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF6DE5B7).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF6DE5B7).withValues(alpha: 0.20)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF7CEAC0),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GREETING
// ============================================================================

class _Greeting extends ConsumerWidget {
  final String farmerName;

  const _Greeting({required this.farmerName});

  String _timeGreeting(bool isHindi) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isHindi ? 'सुप्रभात' : 'Good morning';
    if (hour < 17) return isHindi ? 'नमस्ते' : 'Good afternoon';
    return isHindi ? 'शुभ संध्या' : 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';
    final name = farmerName.trim().isEmpty
        ? (isHindi ? 'किसान' : 'friend')
        : farmerName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_timeGreeting(isHindi)}, $name',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6DE5B7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isHindi ? 'नभकृषि डैशबोर्ड में\nआपका स्वागत है।' : 'Welcome to your\nNabhKrishi dashboard.',
          style: isHindi
              ? GoogleFonts.poppins(color: Colors.white, fontSize: 28, height: 1.16, fontWeight: FontWeight.w700)
              : GoogleFonts.fraunces(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  letterSpacing: -0.3,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          isHindi
              ? 'सिफारिश देखने के लिए नीचे दी गई जानकारी देखें।'
              : 'Review your personalized agricultural metrics below.',
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }
}

// ============================================================================
// FARM HERO (DQN Recommendation Card)
// ============================================================================

class _FarmHero extends ConsumerWidget {
  final Recommendation recommendation;
  final AnimationController floatController;
  final AnimationController ringController;

  const _FarmHero({
    required this.recommendation,
    required this.floatController,
    required this.ringController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        final t = floatController.value;
        final movement = (t - 0.5) * 8;
        final tilt = math.sin(t * math.pi) * 0.006;
        return Transform.translate(
          offset: Offset(0, movement),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isSmall = width < 365;
          final paddingVal = isSmall ? 14.0 : 22.0;
          final ringWidth = isSmall ? 100.0 : 130.0;
          final ringHeight = isSmall ? 120.0 : 150.0;
          final ringSize = isSmall ? 100.0 : 130.0;
          final spacing = isSmall ? 8.0 : 12.0;

          final titleFontSize = isSmall ? 8.5 : 9.5;
          final valueFontSize = isSmall ? 15.0 : 18.0;
          final descFontSize = isSmall ? 9.0 : 10.0;
          final statusFontSize = isSmall ? 7.5 : 8.5;

          final ringAmountFontSize = isSmall ? 32.0 : 41.0;
          final ringUnitFontSize = isSmall ? 8.0 : 9.0;

          final topSpacer = isSmall ? 4.0 : 8.0;
          final midSpacer = isSmall ? 5.0 : 9.0;
          final bottomSpacer = isSmall ? 8.0 : 14.0;

          return Container(
            height: 235,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4A43), Color(0xFF0A3940), Color(0xFF082633)],
              ),
              border: Border.all(color: const Color(0xFF83F0C8).withValues(alpha: 0.13)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF39D49C).withValues(alpha: 0.09),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -35,
                  top: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF82EEC7).withValues(alpha: 0.06),
                        width: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 15,
                  bottom: -12,
                  child: Icon(
                    Icons.water_drop_rounded,
                    size: 115,
                    color: const Color(0xFF8EF1CA).withValues(alpha: 0.045),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(paddingVal),
                  child: Row(
                    children: [
                      SizedBox(
                        width: ringWidth,
                        height: ringHeight,
                        child: AnimatedBuilder(
                          animation: ringController,
                          builder: (context, _) {
                            // Action-based progress representation (0.0 to 1.0 based on max 25mm action)
                            final rawProgress = recommendation.irrigationMm / 25.0;
                            final progress = Curves.easeOutCubic.transform(ringController.value) * rawProgress;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: Size(ringSize, ringSize),
                                  painter: _RingPainter(progress: progress),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${recommendation.irrigationMm.toInt()}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: ringAmountFontSize,
                                        height: 1,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'MM',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF78EAC0),
                                        fontSize: ringUnitFontSize,
                                        letterSpacing: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.translate('irrigation_recommendation', currentLanguage).toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: topSpacer),
                            Text(
                              recommendation.irrigationMm > 0
                                  ? context.translate('apply_irrigation', currentLanguage, arguments: {'amount': '${recommendation.irrigationMm.toInt()}'})
                                  : context.translate('no_irrigation', currentLanguage),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: midSpacer),
                            Text(
                              isHindi
                                  ? 'मौसम और उपग्रह आंकड़ों के आधार पर सुरक्षित निर्णय।'
                                  : 'Recommended amount calculated directly from active weather and Sentinel-1 radar readings.',
                              style: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: descFontSize,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: bottomSpacer),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStatus(
                                    icon: Icons.check_circle_outline_rounded,
                                    label: isHindi ? 'डीक्यूएन मॉडल सत्यापित' : 'DQN model verified',
                                    fontSize: statusFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fontSize;

  const _MiniStatus({required this.icon, required this.label, this.fontSize = 8.5});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF75E8BC)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// WEATHER CARD
// ============================================================================

class _WeatherCard extends ConsumerWidget {
  final WeatherFeatures weather;

  const _WeatherCard({required this.weather});

  String _weatherSummary(bool isHindi) {
    if (weather.tempMean > 30.0 && weather.humidityMean < 50.0) {
      return isHindi ? 'गर्म और अपेक्षाकृत शुष्क दिन' : 'Warm and relatively dry weather';
    } else if (weather.rain7d > 20.0) {
      return isHindi ? 'हाल ही में भारी वर्षा हुई है' : 'Recent rainfall is high';
    } else if (weather.et07d > 25.0) {
      return isHindi ? 'पानी की मांग बढ़ी हुई है' : 'Water demand is currently elevated';
    } else {
      return isHindi ? 'सामान्य और स्थिर मौसम' : 'Stable weather conditions';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.043),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD77C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFD77C), size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.tempMean.toStringAsFixed(1)}°C',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _weatherSummary(isHindi),
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5),
                  ),
                ],
              ),
              const Spacer(),
              _WeatherValue(icon: Icons.water_drop_outlined, value: '${weather.humidityMean.toInt()}%'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          // Expanded weather telemetry metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _WeatherMetricItem(
                  label: context.translate('rainfall_7d', currentLanguage),
                  value: '${weather.rain7d.toStringAsFixed(1)} mm',
                  icon: Icons.grain_rounded,
                ),
              ),
              Expanded(
                child: _WeatherMetricItem(
                  label: context.translate('rainfall_14d', currentLanguage),
                  value: '${weather.rain14d.toStringAsFixed(1)} mm',
                  icon: Icons.umbrella_rounded,
                ),
              ),
              Expanded(
                child: _WeatherMetricItem(
                  label: context.translate('et0_7d', currentLanguage),
                  value: '${weather.et07d.toStringAsFixed(1)} mm',
                  icon: Icons.air_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _WeatherMetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF76EABF), size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: Colors.white30, fontSize: 8),
        ),
      ],
    );
  }
}

class _WeatherValue extends StatelessWidget {
  final IconData icon;
  final String value;

  const _WeatherValue({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFFFD77C)),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 9.5)),
      ],
    );
  }
}

// ============================================================================
// ATTENTION CARD (Field Water Condition Indicator)
// ============================================================================

class _AttentionCard extends ConsumerWidget {
  final WeatherFeatures weather;
  final SentinelFeatures sentinel;

  const _AttentionCard({
    required this.weather,
    required this.sentinel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    // Estimating Field Water Condition based on deficit threshold
    String conditionText = '';
    Color accentColor = const Color(0xFF72E6BA);
    Color cardBgColor = const Color(0xFF092B32);
    IconData icon = Icons.water_drop_outlined;

    if (weather.deficit7d < 10.0) {
      conditionText = context.translate('low_stress', currentLanguage);
      accentColor = const Color(0xFF72E6BA);
      cardBgColor = const Color(0xFF082B24);
      icon = Icons.check_circle_outline_rounded;
    } else if (weather.deficit7d >= 10.0 && weather.deficit7d < 25.0) {
      conditionText = context.translate('moderate_requirement', currentLanguage);
      accentColor = const Color(0xFFFFD77B);
      cardBgColor = const Color(0xFF1D261C);
      icon = Icons.water_drop_outlined;
    } else {
      conditionText = context.translate('high_deficit', currentLanguage);
      accentColor = const Color(0xFFFF8B8B);
      cardBgColor = const Color(0xFF2C161D);
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('estimated_water_condition', currentLanguage),
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  conditionText,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  isHindi
                      ? 'अनुमानित जल घाटा: ${weather.deficit7d.toStringAsFixed(1)} मिमी (यह उपग्रह और जल-संतुलन पर आधारित एक अनुमान है)'
                      : 'Estimated Water Deficit: ${weather.deficit7d.toStringAsFixed(1)} mm (clearly labeled as estimate)',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 8.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SATELLITE CARD
// ============================================================================

class _SatelliteCard extends ConsumerStatefulWidget {
  final SentinelFeatures sentinel;

  const _SatelliteCard({required this.sentinel});

  @override
  ConsumerState<_SatelliteCard> createState() => _SatelliteCardState();
}

class _SatelliteCardState extends ConsumerState<_SatelliteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF8DC7FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.satellite_alt_rounded, color: Color(0xFF8DC7FF), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'सेंटिनल-1 फ्रेशनेस' : 'Satellite Freshness',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.translate('satellite_freshness', currentLanguage, arguments: {
                        'days': '${widget.sentinel.sentinelAgeDays.toInt()}'
                      }),
                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              // More details button
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  backgroundColor: Colors.white.withValues(alpha: 0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  children: [
                    Text(
                      context.translate('more_details', currentLanguage),
                      style: GoogleFonts.poppins(color: const Color(0xFF8DC7FF), fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFF8DC7FF),
                      size: 14,
                    ),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),
            // Technical observation metrics
            _SatelliteMetricRow(
              label: context.translate('vv_mean', currentLanguage),
              value: '${widget.sentinel.vvMean.toStringAsFixed(2)} dB',
              description: isHindi
                  ? 'समतल क्षेत्र पर औसत रडार बैकस्कैटर परावर्तन।'
                  : 'Mean backscatter value representing surface roughness/soil state.',
            ),
            const SizedBox(height: 12),
            _SatelliteMetricRow(
              label: context.translate('vv_change', currentLanguage),
              value: '${widget.sentinel.vvChange.toStringAsFixed(2)} dB',
              description: isHindi
                  ? 'पिछली सैटेलाइट पास से रडार सिग्नल में आया बदलाव।'
                  : 'Radar reflection trend changes indicating wetness fluctuation.',
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                isHindi
                    ? 'नोट: सेंटिनल-1 सीधे मिट्टी की नमी नहीं मापता है। ये मॉडल में उपयोग किए जाने वाले उपग्रह रडार संकेतक हैं।'
                    : 'Accuracy warning: Sentinel-1 does not directly measure soil moisture. These are satellite backscatter features utilized by DQN model.',
                style: GoogleFonts.poppins(color: Colors.white24, fontSize: 8, fontStyle: FontStyle.italic, height: 1.4),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _SatelliteMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String description;

  const _SatelliteMetricRow({
    required this.label,
    required this.value,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
            Text(value, style: GoogleFonts.poppins(color: const Color(0xFF8DC7FF), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        Text(description, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 8.5, height: 1.3)),
      ],
    );
  }
}

// ============================================================================
// EXPLANATION CARD
// ============================================================================

class _ExplanationCard extends ConsumerWidget {
  final LocationPredictionResponse response;

  const _ExplanationCard({required this.response});

  String _generateExplanation(bool isHindi) {
    final rain7d = response.weatherFeatures.rain7d;
    final deficit7d = response.weatherFeatures.deficit7d;
    final et07d = response.weatherFeatures.et07d;
    final amount = response.recommendation.irrigationMm;

    if (amount == 0.0) {
      if (rain7d > 15.0) {
        return isHindi
            ? 'हाल ही में $rain7d मिमी वर्षा पर्याप्त रही है, और अनुमानित जल की कमी कम ($deficit7d मिमी) है, इसलिए प्रणाली सिंचाई की सिफारिश नहीं करती है।'
            : 'Recent rainfall of ${rain7d.toStringAsFixed(1)} mm has been sufficient, and estimated water deficit is low (${deficit7d.toStringAsFixed(1)} mm), so irrigation is not recommended.';
      } else {
        return isHindi
            ? 'अनुमानित जल घाटा स्थिर है और मिट्टी में जल संतुलन संतोषजनक लग रहा है, इसलिए वर्तमान में अतिरिक्त सिंचाई की आवश्यकता नहीं है।'
            : 'Estimated water balance is stable and evapotranspiration demands are low, so no additional irrigation is required.';
      }
    } else {
      if (deficit7d > 10.0 || rain7d < 10.0) {
        return isHindi
            ? 'हाल ही में वर्षा कम (${rain7d.toStringAsFixed(1)} मिमी) हुई है और अनुमानित जल की कमी अधिक (${deficit7d.toStringAsFixed(1)} मिमी) है, इसलिए सिस्टम ${amount.toInt()} मिमी सिंचाई की सलाह देता है।'
            : 'Recent rainfall has been low (${rain7d.toStringAsFixed(1)} mm) and estimated water deficit is high (${deficit7d.toStringAsFixed(1)} mm), so the system recommends applying ${amount.toInt()} mm of irrigation.';
      } else {
        return isHindi
            ? 'हाल की वर्षा की तुलना में पानी की मांग (${et07d.toStringAsFixed(1)} मिमी) अधिक है, इसलिए सिस्टम ${amount.toInt()} मिमी सिंचाई की सलाह देता है।'
            : 'Evapotranspiration demands (${et07d.toStringAsFixed(1)} mm) are elevated compared to recent rainfall, so the system recommends applying ${amount.toInt()} mm of irrigation.';
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Text(
        _generateExplanation(isHindi),
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 11,
          height: 1.5,
        ),
      ),
    );
  }
}

// ============================================================================
// LOADING CARD
// ============================================================================

class _LoadingCard extends StatelessWidget {
  final String stageKey;
  final String currentLanguage;

  const _LoadingCard({
    required this.stageKey,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF6CE6B6).withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: Color(0xFF6CE6B6),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            context.translate(stageKey, currentLanguage),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentLanguage == 'Hindi'
                ? 'कृपया प्रतीक्षा करें, गणना की जा रही है...'
                : 'Processing telemetry through Nabh DQN models...',
            style: GoogleFonts.poppins(color: Colors.white30, fontSize: 9.5),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR CARD
// ============================================================================

class _ErrorCard extends StatelessWidget {
  final String errorKey;
  final String currentLanguage;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.errorKey,
    required this.currentLanguage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF2C161D),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFF8B8B).withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8B8B), size: 38),
          const SizedBox(height: 14),
          Text(
            context.translate('error_title', currentLanguage),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.translate(errorKey, currentLanguage),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8B8B).withValues(alpha: 0.12),
              foregroundColor: const Color(0xFFFF8B8B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              side: const BorderSide(color: Color(0xFFFF8B8B), width: 1),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              context.translate('retry_button', currentLanguage),
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HUMAN ACTIONS
// ============================================================================

class _HumanActions extends ConsumerWidget {
  const _HumanActions();

  Future<void> _handleCropScan(BuildContext context, bool isHindi) async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0C2A34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                isHindi ? 'फसल की फोटो लें या चुनें' : 'Scan Wheat Crop',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHindi
                    ? 'पीला रतुआ और अन्य रोगों की जांच के लिए'
                    : 'For yellow rust and disease detection',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF72E6BA).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF72E6BA), size: 22),
                ),
                title: Text(
                  isHindi ? 'कैमरे से फोटो लें' : 'Take Photo (Camera)',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8DC7FF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF8DC7FF), size: 22),
                ),
                title: Text(
                  isHindi ? 'गैलरी से चुनें' : 'Choose from Gallery',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      if (!context.mounted) return;

      // Show loading indicator during Swin-T model inference
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingCtx) => Dialog(
          backgroundColor: const Color(0xFF0C2A34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF6CE6B6),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    isHindi ? 'पत्ती का विश्लेषण हो रहा है...' : 'Analyzing wheat leaf...',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      CropDiseaseResult? result;
      String? errorMessage;

      try {
        result = await predictCropDisease(pickedFile.path);
      } catch (err) {
        debugPrint('Swin-T disease prediction failed: $err');
        errorMessage = err.toString().replaceFirst('Exception: ', '');
      }

      // Close loading dialog if context is still mounted
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        if (result != null) {
          showDialog(
            context: context,
            builder: (_) => CropDiseaseResultDialog(
              result: result!,
              isHindi: isHindi,
            ),
          );
        } else if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF143844),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFFF8B8B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image for crop scan: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Column(
      children: [
        _ActionCard(
          icon: Icons.auto_awesome_rounded,
          title: isHindi ? 'नभ से पूछें' : 'Ask Nabh',
          subtitle: isHindi ? 'कुछ भी पूछें, आवाज़ में भी' : 'Anything, even by voice',
          accent: const Color(0xFF8DC7FF),
          wide: true,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NabhKrishiChatbotScreen(isHindi: isHindi),
              ),
            );
          },
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _ActionCard(
                icon: Icons.camera_alt_outlined,
                title: isHindi ? 'मेरी फसल देखें' : 'Check my crop',
                subtitle: isHindi ? 'फोटो से जांचें' : 'Take a photo',
                accent: const Color(0xFF72E6BA),
                height: 118,
                onTap: () => _handleCropScan(context, isHindi),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _ActionCard(
                    icon: Icons.storefront_outlined,
                    title: isHindi ? 'आज के भाव' : 'Market',
                    subtitle: isHindi ? 'मंडी भाव' : 'Prices',
                    accent: const Color(0xFFFFD77B),
                    height: 53.5,
                    onTap: () {},
                  ),
                  const SizedBox(height: 11),
                  _ActionCard(
                    icon: Icons.cloud_outlined,
                    title: isHindi ? 'मौसम' : 'Weather',
                    subtitle: isHindi ? '7 दिन' : '7 days',
                    accent: const Color(0xFF9ABEFF),
                    height: 53.5,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool wide;
  final double height;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.wide = false,
    this.height = 103,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 18 : 14,
        vertical: wide ? 14 : (height < 70 ? 8 : 14),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.042),
        borderRadius: wide
            ? BorderRadius.circular(22)
            : const BorderRadius.only(
                topLeft: Radius.circular(21),
                topRight: Radius.circular(19),
                bottomLeft: Radius.circular(19),
                bottomRight: Radius.circular(22),
              ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.065)),
      ),
      child: wide
          ? Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: accent.withValues(alpha: 0.7), size: 18),
              ],
            )
          : height < 70
              ? Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: accent, size: 16),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 7.5)),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 37,
                      height: 37,
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(12)),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 1),
                    Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 8)),
                  ],
                ),
    );

    return _Pressable(onTap: onTap, child: card);
  }
}

// ============================================================================
// NABH MESSAGE
// ============================================================================

class _NabhMessage extends ConsumerStatefulWidget {
  const _NabhMessage();

  @override
  ConsumerState<_NabhMessage> createState() => _NabhMessageState();
}

class _NabhMessageState extends ConsumerState<_NabhMessage> with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      decoration: BoxDecoration(
        color: const Color(0xFF092B32),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6BE6B6).withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_breathController.value);
              final scale = 1.0 + (t * 0.07);
              final glow = 8 + (t * 10);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF79E8BE),
                    boxShadow: [BoxShadow(color: const Color(0xFF79E8BE).withValues(alpha: 0.35), blurRadius: glow)],
                  ),
                  child: const Icon(Icons.eco_rounded, color: Color(0xFF07392C), size: 19),
                ),
              );
            },
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Nabh',
                      style: GoogleFonts.poppins(color: const Color(0xFF73E8BC), fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(color: Color(0xFF73E8BC), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHindi ? 'यहाँ है' : 'here with you',
                      style: GoogleFonts.poppins(color: Colors.white24, fontSize: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isHindi
                      ? '"आपकी फसल स्वस्थ स्थिति में है। बस पानी की सिफारिश पर ध्यान रखें।"'
                      : '"Your crops look stable. Keep monitoring recommendations for optimal watering."',
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 10, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SIMPLE PAGES
// ============================================================================

class _SimplePage extends StatelessWidget {
  final bool isHindi;
  final IconData icon;
  final String title;
  final String subtitle;

  const _SimplePage({required this.isHindi, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6CE6B5).withValues(alpha: 0.08),
                border: Border.all(color: const Color(0xFF6CE6B5).withValues(alpha: 0.12)),
              ),
              child: Icon(icon, color: const Color(0xFF73E8BC), size: 34),
            ),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BOTTOM BAR — a small bounce on the selected icon, not just a color swap.
// ============================================================================

class _BottomBar extends StatelessWidget {
  final int selectedIndex;
  final bool isHindi;
  final ValueChanged<int> onChanged;

  const _BottomBar({required this.selectedIndex, required this.isHindi, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = isHindi ? ['होम', 'अंतर्दृष्टि', 'खेत', 'प्रोफ़ाइल'] : ['Home', 'Insights', 'Farm', 'Profile'];

    final icons = <IconData>[
      Icons.home_rounded,
      Icons.insights_rounded,
      Icons.agriculture_rounded,
      Icons.person_outline_rounded,
    ];

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final paddingBottom = bottomPadding > 0 ? bottomPadding : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, paddingBottom),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF061A27).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(icons.length, (index) {
                final selected = selectedIndex == index;

                return GestureDetector(
                  onTap: () => onChanged(index),
                  behavior: HitTestBehavior.opaque,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1, end: selected ? 1.12 : 1.0),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF6DE7B7).withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[index], color: selected ? const Color(0xFF70E8B9) : Colors.white30, size: 20),
                          const SizedBox(height: 3),
                          Text(
                            labels[index],
                            style: GoogleFonts.poppins(
                              color: selected ? const Color(0xFF70E8B9) : Colors.white30,
                              fontSize: 8,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BACKGROUND — slow drifting glow, so the whole screen feels quietly alive.
// ============================================================================

class _Background extends StatefulWidget {
  const _Background();

  @override
  State<_Background> createState() => _BackgroundState();
}

class _BackgroundState extends State<_Background> with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _breathe;
  late final List<_Blob> _blobs;
  late final List<_Mote> _motes;
  late final List<Offset> _grain;
  late final List<double> _grainOpacity;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(vsync: this, duration: const Duration(seconds: 23))..repeat();
    _breathe = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

    // More presence, more layers, uneven sizes and speeds so the eye keeps
    // finding something new instead of registering one static wash.
    _blobs = [
      _Blob(cx: 0.82, cy: 0.04, radius: 0.46, speed: 0.8, phase: 0.4, color: const Color(0xFF36D49A), alpha: 0.30),
      _Blob(cx: 0.02, cy: 0.58, radius: 0.55, speed: 1.3, phase: 2.6, color: const Color(0xFF2CA9C9), alpha: 0.26),
      _Blob(cx: 0.58, cy: 0.95, radius: 0.4, speed: 0.55, phase: 4.1, color: const Color(0xFF1C8C63), alpha: 0.28),
      _Blob(cx: 0.92, cy: 0.55, radius: 0.3, speed: 1.05, phase: 1.1, color: const Color(0xFF57E0A8), alpha: 0.18),
      _Blob(cx: 0.22, cy: 0.12, radius: 0.26, speed: 0.9, phase: 3.4, color: const Color(0xFF1A7FA8), alpha: 0.20),
    ];

    final rng = math.Random(11);
    _grain = List.generate(180, (_) => Offset(rng.nextDouble(), rng.nextDouble()));
    _grainOpacity = List.generate(180, (_) => rng.nextDouble() * 0.035 + 0.01);

    // Slow-rising motes — like dust or spores catching light. This is the
    // biggest single fix for "dead": something is always quietly moving.
    _motes = List.generate(22, (i) => _Mote(seed: i));
  }

  @override
  void dispose() {
    _drift.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_drift, _breathe]),
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _OrganicBackgroundPainter(
            t: _drift.value,
            breathe: _breathe.value,
            blobs: _blobs,
            motes: _motes,
            grain: _grain,
            grainOpacity: _grainOpacity,
          ),
        );
      },
    );
  }
}

class _Blob {
  final double cx, cy, radius, speed, phase, alpha;
  final Color color;
  _Blob({
    required this.cx,
    required this.cy,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
    this.alpha = 0.16,
  });
}

class _Mote {
  final double x, startDelay, sizeFactor, drift, speed;
  _Mote({required int seed})
      : x = math.Random(seed * 13).nextDouble(),
        startDelay = math.Random(seed * 29).nextDouble(),
        sizeFactor = 0.5 + math.Random(seed * 47).nextDouble() * 1.4,
        drift = (math.Random(seed * 61).nextDouble() - 0.5) * 40,
        speed = 0.6 + math.Random(seed * 79).nextDouble() * 0.8;
}

class _OrganicBackgroundPainter extends CustomPainter {
  final double t;
  final double breathe;
  final List<_Blob> blobs;
  final List<_Mote> motes;
  final List<Offset> grain;
  final List<double> grainOpacity;

  _OrganicBackgroundPainter({
    required this.t,
    required this.breathe,
    required this.blobs,
    required this.motes,
    required this.grain,
    required this.grainOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base is a touch lighter than before and has its own gentle vertical
    // shift, so even the "empty" canvas isn't perfectly flat.
    final baseTop = Color.lerp(const Color(0xFF04252D), const Color(0xFF052A30), breathe)!;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [baseTop, const Color(0xFF041F26)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final shortSide = math.min(size.width, size.height);
    final breathScale = 1.0 + (breathe * 0.06);

    for (final b in blobs) {
      final angle = t * 2 * math.pi * b.speed + b.phase;
      final dx = math.sin(angle) * 0.05 + math.sin(angle * 1.9) * 0.018;
      final dy = math.cos(angle * 0.7 + b.phase) * 0.045;

      final center = Offset((b.cx + dx) * size.width, (b.cy + dy) * size.height);
      final r = b.radius * shortSide * breathScale;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color.withValues(alpha: b.alpha), b.color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: center, radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 75);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(b.phase);
      canvas.scale(1.0, 0.78 + 0.14 * math.sin(b.phase * 1.3));
      canvas.drawCircle(Offset.zero, r, paint);
      canvas.restore();
    }

    // Rising motes — small glowing points drifting upward and fading,
    // the thing that makes a background read as alive rather than static.
    for (final m in motes) {
      final localT = (t * m.speed + m.startDelay) % 1.0;
      final y = size.height * (1 - localT);
      final opacity = math.sin(localT * math.pi).clamp(0.0, 1.0) * 0.5;
      final x = m.x * size.width + math.sin(localT * 2 * math.pi) * m.drift;

      canvas.drawCircle(
        Offset(x, y),
        1.6 * m.sizeFactor,
        Paint()..color = const Color(0xFF9FF3D2).withValues(alpha: opacity * 0.55),
      );
    }

    // Grain — fixed texture, not regenerated per frame.
    for (int i = 0; i < grain.length; i++) {
      final p = grain[i];
      canvas.drawCircle(
        Offset(p.dx * size.width, p.dy * size.height),
        0.8,
        Paint()..color = Colors.white.withValues(alpha: grainOpacity[i]),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicBackgroundPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.breathe != breathe;
}

// ============================================================================
// RING
// ============================================================================

class _RingPainter extends CustomPainter {
  final double progress;

  _RingPainter({required this.progress});

  // A fixed, deterministic wobble — same every rebuild, so the ring reads
  // as "drawn slightly by hand" rather than perfectly compass-drawn, without
  // ever jittering or looking glitchy as progress animates.
  static const int _points = 120;
  static final List<double> _wobble = List.generate(
    _points,
    (i) => math.sin(i * 0.9) * 0.9 + math.sin(i * 2.3 + 1.2) * 0.5,
  );

  Path _wobblyCirclePath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i <= _points; i++) {
      final angle = (i / _points) * 2 * math.pi;
      final r = radius + _wobble[i % _points];
      final point = Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final background = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_wobblyCirclePath(center, radius), background);

    // Progress arc: clip a wedge of the same wobbly circle so the fill
    // matches the hand-drawn outline rather than a mathematically perfect arc.
    final sweep = 6.28318 * progress;
    final clipPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius + 10), -1.57, sweep, false)
      ..close();

    canvas.save();
    canvas.clipPath(clipPath);

    final foreground = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFB8FFE1), Color(0xFF43D19B)]).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_wobblyCirclePath(center, radius), foreground);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================================
// RECOMMENDATION SECTION (Performance Isolated State Watcher)
// ============================================================================

class _RecommendationSection extends ConsumerWidget {
  final LatLng centroid;
  final AnimationController floatController;
  final AnimationController entranceController;
  final AnimationController ringController;

  const _RecommendationSection({
    required this.centroid,
    required this.floatController,
    required this.entranceController,
    required this.ringController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';
    final coordinateKey = '${centroid.latitude.toStringAsFixed(4)},${centroid.longitude.toStringAsFixed(4)}';
    final irrigationState = ref.watch(irrigationProvider(coordinateKey));

    if (irrigationState.isLoading) {
      return _Reveal(
        controller: entranceController,
        start: 0.15,
        child: _LoadingCard(
          stageKey: irrigationState.loadingStage,
          currentLanguage: currentLanguage,
        ),
      );
    } else if (irrigationState.errorMessage != null) {
      return _Reveal(
        controller: entranceController,
        start: 0.15,
        child: _ErrorCard(
          errorKey: irrigationState.errorMessage!,
          currentLanguage: currentLanguage,
          onRetry: () {
            ref.read(irrigationProvider(coordinateKey).notifier)
                .fetchRecommendation(centroid.latitude, centroid.longitude);
          },
        ),
      );
    } else if (irrigationState.data != null) {
      final data = irrigationState.data!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Reveal(
            controller: entranceController,
            start: 0.15,
            child: _FarmHero(
              recommendation: data.recommendation,
              floatController: floatController,
              ringController: ringController,
            ),
          ),
          const SizedBox(height: 22),
          _Reveal(
            controller: entranceController,
            start: 0.20,
            child: _WeatherCard(weather: data.weatherFeatures),
          ),
          const SizedBox(height: 25),
          _Reveal(
            controller: entranceController,
            start: 0.25,
            child: _SectionTitle(
              title: context.translate('field_condition', currentLanguage),
              subtitle: isHindi
                  ? 'मिट्टी की जल सामग्री और उपग्रह अवलोकनों का अनुमान'
                  : 'Water deficit assessment and latest satellite readings',
            ),
          ),
          const SizedBox(height: 12),
          _Reveal(
            controller: entranceController,
            start: 0.28,
            child: _AttentionCard(
              weather: data.weatherFeatures,
              sentinel: data.sentinelFeatures,
            ),
          ),
          const SizedBox(height: 25),
          _Reveal(
            controller: entranceController,
            start: 0.32,
            child: _SectionTitle(
              title: context.translate('satellite_section', currentLanguage),
              subtitle: isHindi
                  ? 'सेंटिनल-1 उपग्रह सक्रिय रडार माप'
                  : 'Sentinel-1 active radar telemetry indicators',
            ),
          ),
          const SizedBox(height: 12),
          _Reveal(
            controller: entranceController,
            start: 0.35,
            child: _SatelliteCard(sentinel: data.sentinelFeatures),
          ),
          const SizedBox(height: 25),
          _Reveal(
            controller: entranceController,
            start: 0.38,
            child: _SectionTitle(
              title: context.translate('explanation_title', currentLanguage),
              subtitle: isHindi
                  ? 'मौसम और उपग्रह आंकड़ों का विश्लेषण'
                  : 'Calculated from cumulative rain, evapotranspiration, and radar change',
            ),
          ),
          const SizedBox(height: 12),
          _Reveal(
            controller: entranceController,
            start: 0.40,
            child: _ExplanationCard(
              response: data,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ============================================================================
// MANUAL COORDINATES INPUT WIDGET
// ============================================================================

class _ManualCoordinatesInput extends ConsumerStatefulWidget {
  const _ManualCoordinatesInput();

  @override
  ConsumerState<_ManualCoordinatesInput> createState() => _ManualCoordinatesInputState();
}

class _ManualCoordinatesInputState extends ConsumerState<_ManualCoordinatesInput> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _locateFarm(bool isHindi) {
    final latVal = double.tryParse(_latController.text);
    final lngVal = double.tryParse(_lngController.text);

    if (latVal == null || latVal < -90.0 || latVal > 90.0) {
      setState(() {
        _validationError = isHindi ? 'अमान्य अक्षांश (-90 से 90)' : 'Invalid Latitude (-90 to 90)';
      });
      return;
    }

    if (lngVal == null || lngVal < -180.0 || lngVal > 180.0) {
      setState(() {
        _validationError = isHindi ? 'अमान्य देशांतर (-180 से 180)' : 'Invalid Longitude (-180 to 180)';
      });
      return;
    }

    setState(() {
      _validationError = null;
    });

    FocusScope.of(context).unfocus();
    ref.read(locationProvider.notifier).updateCoordinate(latVal, lngVal);
    ref.read(locationProvider.notifier).clearBoundary(); // Reset boundary for manual point search
    
    // Automatically confirm/select the farm location on manual search
    final activeLoc = ref.read(locationProvider);
    ref.read(confirmedLocationProvider.notifier).state = activeLoc.copyWith(isDrawing: false);
    ref.read(locationProvider.notifier).toggleDrawing(false);
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CoordinateField(
                controller: _latController,
                label: isHindi ? 'अक्षांश (Lat)' : 'Latitude',
                hint: '28.6139',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CoordinateField(
                controller: _lngController,
                label: isHindi ? 'देशांतर (Lng)' : 'Longitude',
                hint: '77.2090',
              ),
            ),
          ],
        ),
        if (_validationError != null) ...[
          const SizedBox(height: 6),
          Text(
            _validationError!,
            style: GoogleFonts.poppins(color: const Color(0xFFFF8B8B), fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6CE6B6).withValues(alpha: 0.08),
              foregroundColor: const Color(0xFF6CE6B6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF6CE6B6), width: 1),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
            ),
            icon: const Icon(Icons.search_rounded, size: 16),
            label: Text(
              isHindi ? 'खेत का स्थान खोजें' : 'Locate Farm',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _locateFarm(isHindi),
          ),
        ),
      ],
    );
  }
}

class _CoordinateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _CoordinateField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 12.5),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

// FARM LOCATION DETAILS CARD & SAVE SUMMARY DIALOG
// ============================================================================

class _FarmLocationDetailsCard extends ConsumerWidget {
  const _FarmLocationDetailsCard();

  void _showSummaryDialog(BuildContext context, WidgetRef ref, LocationData loc, bool isHindi) {
    final coordinateKey = '${loc.latitude.toStringAsFixed(4)},${loc.longitude.toStringAsFixed(4)}';
    final irrigationState = ref.read(irrigationProvider(coordinateKey));
    
    String advisory = isHindi ? 'सिंचाई की सिफारिश लोड हो रही है...' : 'Loading recommendation...';
    if (irrigationState.data != null) {
      final rec = irrigationState.data!.recommendation;
      if (rec.irrigationMm > 0) {
        advisory = isHindi 
            ? '${rec.irrigationMm.toInt()} मिमी सिंचाई करें' 
            : 'Apply ${rec.irrigationMm.toInt()} mm irrigation';
      } else {
        advisory = isHindi ? 'सिंचाई की आवश्यकता नहीं है' : 'No irrigation required';
      }
    } else if (irrigationState.errorMessage != null) {
      advisory = isHindi ? 'कनेक्शन त्रुटि। कृपया पुनः प्रयास करें।' : 'Connection error. Please try again.';
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0C2A34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF6CE6B6), size: 24),
                    const SizedBox(width: 8),
                    Text(
                      isHindi ? 'खेत सहेजा गया!' : 'Farm Saved!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  isHindi ? 'खेत का स्थान (Farm Location)' : 'Farm Location',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isHindi ? 'अक्षांश' : 'Latitude'}: ${loc.latitude.toStringAsFixed(5)}\n${isHindi ? 'देशांतर' : 'Longitude'}: ${loc.longitude.toStringAsFixed(5)}',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
                ),
                const SizedBox(height: 16),
                Text(
                  isHindi ? 'खेत का क्षेत्रफल (Farm Area)' : 'Farm Area',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.boundary.length >= 3
                      ? '${loc.farmAreaHectares.toStringAsFixed(2)} ${isHindi ? 'हेक्टेयर' : 'hectares'}'
                      : (isHindi ? 'बिंदु स्थान' : 'Point location'),
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Text(
                  isHindi ? 'सिंचाई सलाह (Irrigation Advisory)' : 'Irrigation Advisory',
                  style: GoogleFonts.poppins(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  advisory,
                  style: GoogleFonts.poppins(color: const Color(0xFF6CE6B6), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isHindi ? 'बंद करें' : 'Close',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';
    final confirmedLoc = ref.watch(confirmedLocationProvider);
    
    final latStr = confirmedLoc.latitude.toStringAsFixed(5);
    final lngStr = confirmedLoc.longitude.toStringAsFixed(5);
    final area = confirmedLoc.farmAreaHectares;
    final hasBoundary = confirmedLoc.boundary.length >= 3;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2A34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6CE6B6).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.agriculture_rounded, color: Color(0xFF6CE6B6), size: 20),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'खेत का विवरण' : 'Farm Details',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'अक्षांश (Lat)' : 'Latitude',
                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      latStr,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'देशांतर (Lng)' : 'Longitude',
                      style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lngStr,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.translate('farm_area', currentLanguage),
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                hasBoundary
                    ? '${area.toStringAsFixed(2)} ${context.translate('hectares', currentLanguage)}'
                    : (isHindi ? 'बिंदु स्थान (सीमा नहीं खींची गई)' : 'Point location (no boundary drawn)'),
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6CE6B6),
                foregroundColor: const Color(0xFF031A22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                elevation: 4,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: Text(
                context.translate('save_farm', currentLanguage),
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF0C2A34),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        isHindi ? 'साइन इन आवश्यक' : 'Sign In Required',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      content: Text(
                        isHindi ? 'खेत सहेजने से पहले कृपया साइन इन करें।' : 'Please sign in before saving your farm.',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            isHindi ? 'बंद करें' : 'Close',
                            style: GoogleFonts.poppins(color: const Color(0xFF6CE6B6), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6CE6B6)),
                    ),
                  ),
                );

                try {
                  final firestoreService = ref.read(firestoreServiceProvider);
                  final farm = FarmModel(
                    farmId: '',
                    userId: user.uid,
                    latitude: confirmedLoc.latitude,
                    longitude: confirmedLoc.longitude,
                    farmArea: confirmedLoc.boundary.length >= 3 ? confirmedLoc.farmAreaHectares : null,
                    areaUnit: confirmedLoc.boundary.length >= 3 ? 'hectares' : null,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  await firestoreService.saveFarm(user.uid, farm);
                  
                  // Pop loading indicator
                  if (context.mounted) {
                    Navigator.pop(context);
                    // Show success summary dialog
                    _showSummaryDialog(context, ref, confirmedLoc, isHindi);
                  }
                } catch (e) {
                  // Pop loading indicator
                  if (context.mounted) {
                    Navigator.pop(context);
                    // Show error dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF0C2A34),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          isHindi ? 'सहेजने में असमर्थ' : 'Error Saving Farm',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        content: Text(
                          isHindi ? 'खेत सहेजने में विफल: $e' : 'Failed to save farm: $e',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              isHindi ? 'बंद करें' : 'Close',
                              style: GoogleFonts.poppins(color: const Color(0xFF6CE6B6), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FARMER FEEDBACK CARD & DIALOG
// ============================================================================

class _FeedbackCard extends ConsumerWidget {
  const _FeedbackCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);
    final isHindi = currentLanguage == 'Hindi';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2A34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_rounded, color: Color(0xFF6CE6B6), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isHindi ? 'नभकृषि को बेहतर बनाने में मदद करें' : 'Help us improve NabhKrishi',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isHindi 
                ? 'हमारी सिंचाई सिफारिशें आपके लिए कितनी उपयोगी हैं?' 
                : 'How useful are our irrigation recommendations?',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6CE6B6),
                foregroundColor: const Color(0xFF031A22),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _FeedbackDialog(isHindi: isHindi),
                );
              },
              child: Text(
                isHindi ? 'प्रतिक्रिया दें' : 'Give Feedback',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackDialog extends ConsumerStatefulWidget {
  final bool isHindi;
  const _FeedbackDialog({required this.isHindi});

  @override
  ConsumerState<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<_FeedbackDialog> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0C2A34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isHindi ? 'प्रतिक्रिया फॉर्म' : 'Farmer Feedback',
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isHindi ? 'नभकृषि रेटिंग:' : 'Rate NabhKrishi:',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final filled = starIndex <= _rating;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: filled ? const Color(0xFFFFB300) : Colors.white24,
                      size: 30,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              widget.isHindi ? 'टिप्पणियां (वैकल्पिक):' : 'Comments (optional):',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 3,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: widget.isHindi ? 'अपनी प्रतिक्रिया यहाँ लिखें...' : 'Write comments here...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(
            widget.isHindi ? 'रद्द करें' : 'Cancel',
            style: GoogleFonts.poppins(color: Colors.white30, fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6CE6B6),
            foregroundColor: const Color(0xFF031A22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          onPressed: _submitting ? null : _submitFeedback,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF031A22)),
                )
              : Text(
                  widget.isHindi ? 'जमा करें' : 'Submit',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    setState(() {
      _submitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(widget.isHindi ? 'कोई उपयोगकर्ता साइन इन नहीं है।' : 'No user is signed in.');
      }

      await ref.read(firestoreServiceProvider).saveFeedback(
            userId: user.uid,
            rating: _rating,
            feedback: _feedbackController.text,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isHindi ? 'प्रतिक्रिया सफलतापूर्वक सहेजी गई!' : 'Feedback submitted successfully!',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF0C2A34),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _submitting = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0C2A34),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              widget.isHindi ? 'प्रस्तुत करने में विफल' : 'Submission Failed',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Text(
              widget.isHindi ? 'प्रतिक्रिया भेजने में विफल: $e' : 'Failed to submit feedback: $e',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  widget.isHindi ? 'बंद करें' : 'Close',
                  style: GoogleFonts.poppins(color: const Color(0xFF6CE6B6), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}
