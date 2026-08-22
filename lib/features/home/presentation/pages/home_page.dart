import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int selectedIndex = 0;

  // Gentle up/down drift on the hero card — makes it feel like it's breathing.
  late final AnimationController _floatController;

  // Drives the staggered "wake up" of the dashboard on first load.
  late final AnimationController _entranceController;

  // Draws the health ring in rather than snapping it straight to 82%.
  late final AnimationController _ringController;

  bool get isHindi => widget.language == 'Hindi';

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
                  isHindi: isHindi,
                  farmerName: widget.farmerName,
                  streakDays: widget.streakDays,
                  floatController: _floatController,
                  entranceController: _entranceController,
                  ringController: _ringController,
                ),
                _SimplePage(
                  isHindi: isHindi,
                  icon: Icons.insights_rounded,
                  title: isHindi ? 'आपकी खेती' : 'Your insights',
                  subtitle: isHindi
                      ? 'आपके खेत की कहानी यहाँ दिखेगी।'
                      : 'The story of your farm will live here.',
                ),
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

// ============================================================================
// DASHBOARD
// ============================================================================

class _Dashboard extends StatelessWidget {
  final bool isHindi;
  final String farmerName;
  final int streakDays;
  final AnimationController floatController;
  final AnimationController entranceController;
  final AnimationController ringController;

  const _Dashboard({
    required this.isHindi,
    required this.farmerName,
    required this.streakDays,
    required this.floatController,
    required this.entranceController,
    required this.ringController,
  });

  @override
  Widget build(BuildContext context) {
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
                child: _StreakRibbon(isHindi: isHindi, streakDays: streakDays),
              ),

              const SizedBox(height: 22),

              _Reveal(
                controller: entranceController,
                start: 0.06,
                child: _Greeting(isHindi: isHindi, farmerName: farmerName),
              ),

              const SizedBox(height: 22),

              _Reveal(
                controller: entranceController,
                start: 0.12,
                child: _FarmHero(
                  isHindi: isHindi,
                  floatController: floatController,
                  ringController: ringController,
                ),
              ),

              const SizedBox(height: 18),

              _Reveal(
                controller: entranceController,
                start: 0.18,
                child: _WeatherCard(isHindi: isHindi),
              ),

              const SizedBox(height: 30),

              _Reveal(
                controller: entranceController,
                start: 0.24,
                child: _SectionTitle(
                  title: isHindi ? 'आज आपके खेत के लिए' : 'For your farm today',
                  subtitle: isHindi
                      ? 'कुछ छोटा, लेकिन ज़रूरी।'
                      : 'One small thing worth knowing.',
                ),
              ),

              const SizedBox(height: 14),

              _Reveal(
                controller: entranceController,
                start: 0.28,
                child: _AttentionCard(isHindi: isHindi),
              ),

              const SizedBox(height: 30),

              _Reveal(
                controller: entranceController,
                start: 0.34,
                child: _SectionTitle(
                  title: isHindi ? 'कुछ चाहिए?' : 'Need something?',
                  subtitle: isHindi ? 'NabhKrishi यहाँ है।' : 'NabhKrishi is here.',
                ),
              ),

              const SizedBox(height: 14),

              _Reveal(
                controller: entranceController,
                start: 0.4,
                child: _HumanActions(isHindi: isHindi),
              ),

              const SizedBox(height: 30),

              _Reveal(
                controller: entranceController,
                start: 0.48,
                child: _NabhMessage(isHindi: isHindi),
              ),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TOP BAR
// ============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
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
        _SmallButton(icon: Icons.notifications_none_rounded, dot: true, onTap: () {}),
        const SizedBox(width: 8),
        _SmallButton(icon: Icons.person_outline_rounded, onTap: () {}),
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

class _StreakRibbon extends StatelessWidget {
  final bool isHindi;
  final int streakDays;

  const _StreakRibbon({required this.isHindi, required this.streakDays});

  @override
  Widget build(BuildContext context) {
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
// GREETING — personal, time-aware, not a template string.
// ============================================================================

class _Greeting extends StatelessWidget {
  final bool isHindi;
  final String farmerName;

  const _Greeting({required this.isHindi, required this.farmerName});

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return isHindi ? 'सुप्रभात' : 'Good morning';
    if (hour < 17) return isHindi ? 'नमस्ते' : 'Good afternoon';
    return isHindi ? 'शुभ संध्या' : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = farmerName.trim().isEmpty
        ? (isHindi ? 'किसान' : 'friend')
        : farmerName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_timeGreeting()}, $name',
          style: GoogleFonts.poppins(
            color: const Color(0xFF6DE5B7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isHindi ? 'आज आपके खेत के लिए\nएक अच्छी खबर है।' : 'Your farm is having\na good day.',
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
              ? 'बस एक छोटी सी चीज़ पर ध्यान देना है।'
              : 'There\u2019s just one little thing worth checking.',
          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11, height: 1.5),
        ),
      ],
    );
  }
}

// ============================================================================
// FARM HERO
// ============================================================================

class _FarmHero extends StatelessWidget {
  final bool isHindi;
  final AnimationController floatController;
  final AnimationController ringController;

  const _FarmHero({
    required this.isHindi,
    required this.floatController,
    required this.ringController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, child) {
        final t = floatController.value;
        final movement = (t - 0.5) * 8;
        // A hair of rotation alongside the float — a card that only ever
        // moves straight up and down reads as a CSS keyframe, not a
        // physical object settling.
        final tilt = math.sin(t * math.pi) * 0.006;
        return Transform.translate(
          offset: Offset(0, movement),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: Container(
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
                Icons.grass_rounded,
                size: 115,
                color: const Color(0xFF8EF1CA).withValues(alpha: 0.045),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 180,
                    child: AnimatedBuilder(
                      animation: ringController,
                      builder: (context, _) {
                        final progress = Curves.easeOutCubic.transform(ringController.value) * 0.82;
                        final shown = (progress * 100).round();
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(size: const Size(140, 140), painter: _RingPainter(progress: progress)),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$shown',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 41,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isHindi ? 'स्वस्थ' : 'LOOKING GOOD',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF78EAC0),
                                    fontSize: 8,
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
                  const SizedBox(width: 3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isHindi ? 'आपका खेत' : 'Your farm',
                          style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHindi ? 'आज खुश लग रहा है।' : 'Feels healthy today.',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          isHindi
                              ? 'मिट्टी और फसल के संकेत सामान्य हैं।'
                              : 'Your soil and crop signals are looking healthy.',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10, height: 1.5),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _MiniStatus(icon: Icons.landscape_outlined, label: isHindi ? 'मिट्टी अच्छी' : 'Soil good'),
                            const SizedBox(width: 8),
                            _MiniStatus(icon: Icons.grass_rounded, label: isHindi ? 'फसल स्वस्थ' : 'Crop healthy'),
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
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniStatus({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF75E8BC)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 8)),
      ],
    );
  }
}

// ============================================================================
// WEATHER
// ============================================================================

class _WeatherCard extends StatelessWidget {
  final bool isHindi;

  const _WeatherCard({required this.isHindi});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.043),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
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
              Text('27°C', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                isHindi ? 'आज शाम गर्मी रहेगी' : 'A warm evening ahead',
                style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
          const Spacer(),
          _WeatherValue(icon: Icons.water_drop_outlined, value: '72%'),
          const SizedBox(width: 12),
          _WeatherValue(icon: Icons.air_rounded, value: '12 km/h'),
        ],
      ),
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
        Icon(icon, size: 13, color: Colors.white30),
        const SizedBox(width: 4),
        Text(value, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 8.5)),
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
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: GoogleFonts.poppins(color: Colors.white30, fontSize: 9.5)),
      ],
    );
  }
}

// ============================================================================
// ATTENTION — now tappable, with a soft press response.
// ============================================================================

class _AttentionCard extends StatelessWidget {
  final bool isHindi;

  const _AttentionCard({required this.isHindi});

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF172B32),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFFE6C66B).withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE7C96E).withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.water_drop_outlined, color: Color(0xFFF0D77E), size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? 'शायद आज पानी देना सही रहेगा' : 'Your field may need some water',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHindi ? 'शाम को तापमान बढ़ने वाला है।' : 'Temperatures are expected to rise this evening.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 9.5, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HUMAN ACTIONS
// ============================================================================

class _HumanActions extends StatelessWidget {
  final bool isHindi;

  const _HumanActions({required this.isHindi});

  @override
  Widget build(BuildContext context) {
    // Ask Nabh gets the most real estate — it's the thing a first-time,
    // low-literacy user is most likely to reach for, so the layout says
    // that before any copy does. Everything else sits underneath, unequal
    // on purpose, instead of four identical tiles in a grid.
    return Column(
      children: [
        _ActionCard(
          icon: Icons.auto_awesome_rounded,
          title: isHindi ? 'नभ से पूछें' : 'Ask Nabh',
          subtitle: isHindi ? 'कुछ भी पूछें, आवाज़ में भी' : 'Anything, even by voice',
          accent: const Color(0xFF8DC7FF),
          wide: true,
          onTap: () {},
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
                onTap: () {},
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
      padding: EdgeInsets.symmetric(horizontal: wide ? 18 : 14, vertical: wide ? 14 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.042),
        // Slightly uneven corners rather than a perfect uniform radius —
        // small enough not to look broken, distinct enough not to look CAD-drawn.
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
// NABH MESSAGE — Nabh now visibly "breathes" and shows it's present,
// like someone who's actually paying attention to your farm.
// ============================================================================

class _NabhMessage extends StatefulWidget {
  final bool isHindi;

  const _NabhMessage({required this.isHindi});

  @override
  State<_NabhMessage> createState() => _NabhMessageState();
}

class _NabhMessageState extends State<_NabhMessage> with SingleTickerProviderStateMixin {
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
    final isHindi = widget.isHindi;

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
                      ? '"आपका खेत आज अच्छा कर रहा है। बस पानी पर थोड़ा ध्यान रखिए।"'
                      : '"Your farm is doing well today. Just keep an eye on the water."',
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
