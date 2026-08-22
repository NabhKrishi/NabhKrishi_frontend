import 'dart:ui';
import '../../../home/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  final String language;

  const LoginPage({super.key, required this.language});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _showOtp = false;
  bool _loading = false;
  String? _error;

  bool get isHindi => widget.language == 'Hindi';

  String get title =>
      isHindi ? 'नाभकृषि में आपका स्वागत है' : 'Welcome to NabhKrishi';

  String get subtitle => isHindi
      ? 'आपकी खेती, हमारे साथ और स्मार्ट।'
      : 'Your farm. Your future. Smarter.';

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      setState(() {
        _error = isHindi
            ? 'कृपया 10 अंकों का मोबाइल नंबर दर्ज करें।'
            : 'Please enter a valid 10-digit mobile number.';
      });
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _showOtp = true;
      });
    });
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();

    final otp = _otpController.text.trim();

    if (otp.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(otp)) {
      setState(() {
        _error = isHindi
            ? 'कृपया 6 अंकों का OTP दर्ज करें।'
            : 'Please enter the 6-digit OTP.';
      });
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSuccess();
    });
  }

  void _showSuccess() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3150).withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF6AE8BE).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF5DE2B0,
                            ).withValues(alpha: 0.14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF5DE2B0,
                                ).withValues(alpha: 0.22),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF72F0C1),
                            size: 40,
                          ),
                        ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        ),

                        const SizedBox(height: 22),

                        Text(
                          isHindi ? 'सत्यापन सफल!' : 'Verification successful!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          isHindi
                              ? 'लॉगिन पूरा हो गया है।'
                              : 'Your login is complete.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 26),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);

                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(
                                    milliseconds: 650,
                                  ),
                                  pageBuilder: (_, animation, __) {
                                    return HomePage(language: widget.language);
                                  },
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                        final curved = CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        );

                                        return FadeTransition(
                                          opacity: curved,
                                          child: SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(0, 0.025),
                                              end: Offset.zero,
                                            ).animate(curved),
                                            child: child,
                                          ),
                                        );
                                      },
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6AE8BE),
                              foregroundColor: const Color(0xFF063B2D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              isHindi ? 'आगे बढ़ें' : 'Continue',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _googleLogin() {
    setState(() {
      _error = null;
      _loading = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04172F),
      body: Stack(
        children: [
          const _LoginBackground(),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onPressed: () => Navigator.pop(context)),

                  const SizedBox(height: 34),

                  Center(
                    child: const _MiniLeaf()
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          end: const Offset(1, 1),
                          duration: 650.ms,
                          curve: Curves.easeOutBack,
                        ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 29,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 500.ms)
                      .moveY(
                        begin: 18,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 10),

                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 180.ms, duration: 500.ms),

                  const SizedBox(height: 42),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _showOtp
                        ? _OtpSection(
                            key: const ValueKey('otp'),
                            controller: _otpController,
                            phone: _phoneController.text,
                            isHindi: isHindi,
                            loading: _loading,
                            error: _error,
                            onVerify: _verifyOtp,
                            onBack: () {
                              setState(() {
                                _showOtp = false;
                                _error = null;
                                _otpController.clear();
                              });
                            },
                          )
                        : _PhoneSection(
                            key: const ValueKey('phone'),
                            controller: _phoneController,
                            isHindi: isHindi,
                            loading: _loading,
                            error: _error,
                            onContinue: _continue,
                            onGoogle: _googleLogin,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PHONE SECTION
// -----------------------------------------------------------------------------

class _PhoneSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isHindi;
  final bool loading;
  final String? error;
  final VoidCallback onContinue;
  final VoidCallback onGoogle;

  const _PhoneSection({
    super.key,
    required this.controller,
    required this.isHindi,
    required this.loading,
    required this.error,
    required this.onContinue,
    required this.onGoogle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _GlassField(
          controller: controller,
          prefix: '+91',
          hint: isHindi ? 'मोबाइल नंबर' : 'Mobile number',
          keyboardType: TextInputType.phone,
          error: error,
        ),

        if (error != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              error!,
              style: GoogleFonts.poppins(
                color: const Color(0xFFFFA7A7),
                fontSize: 12,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        _GlowButton(
          text: isHindi ? 'जारी रखें' : 'Continue',
          loading: loading,
          onPressed: onContinue,
        ),

        const SizedBox(height: 26),

        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                isHindi ? 'या' : 'OR',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _GoogleButton(isHindi: isHindi, loading: loading, onPressed: onGoogle),

        const SizedBox(height: 22),

        Text(
          isHindi
              ? 'जारी रखकर आप हमारी शर्तों और गोपनीयता नीति से सहमत हैं।'
              : 'By continuing, you agree to our Terms and Privacy Policy.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// OTP SECTION
// -----------------------------------------------------------------------------

class _OtpSection extends StatelessWidget {
  final TextEditingController controller;
  final String phone;
  final bool isHindi;
  final bool loading;
  final String? error;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  const _OtpSection({
    super.key,
    required this.controller,
    required this.phone,
    required this.isHindi,
    required this.loading,
    required this.error,
    required this.onVerify,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isHindi ? 'आपका नंबर सत्यापित करें' : 'Verify your number',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          isHindi
              ? '+91 $phone पर 6 अंकों का कोड भेजा गया है।'
              : 'We sent a 6-digit code to +91 $phone.',
          style: GoogleFonts.poppins(
            color: Colors.white60,
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 28),

        _OtpField(controller: controller, isHindi: isHindi),

        if (error != null) ...[
          const SizedBox(height: 10),
          Text(
            error!,
            style: GoogleFonts.poppins(
              color: const Color(0xFFFFA7A7),
              fontSize: 12,
            ),
          ),
        ],

        const SizedBox(height: 22),

        _GlowButton(
          text: isHindi ? 'सत्यापित करें' : 'Verify',
          loading: loading,
          onPressed: onVerify,
        ),

        const SizedBox(height: 18),

        Center(
          child: TextButton(
            onPressed: onBack,
            child: Text(
              isHindi ? 'नंबर बदलें' : 'Change number',
              style: GoogleFonts.poppins(
                color: const Color(0xFF72E9BF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        Center(
          child: Text(
            isHindi
                ? 'OTP नहीं मिला? थोड़ी देर बाद फिर कोशिश करें।'
                : "Didn't receive the code? Try again shortly.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// COMPONENTS
// -----------------------------------------------------------------------------

class _GlassField extends StatefulWidget {
  final TextEditingController controller;
  final String prefix;
  final String hint;
  final TextInputType keyboardType;
  final String? error;

  const _GlassField({
    required this.controller,
    required this.prefix,
    required this.hint,
    required this.keyboardType,
    required this.error,
  });

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: focused
                ? const Color(0xFF6AE8BE).withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.10),
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF5DE2B0).withValues(alpha: 0.12),
                    blurRadius: 28,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Text(
              widget.prefix,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 1,
              height: 25,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: widget.keyboardType,
                maxLength: 10,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: widget.hint,
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.32),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpField extends StatefulWidget {
  final TextEditingController controller;
  final bool isHindi;

  const _OtpField({required this.controller, required this.isHindi});

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        setState(() {
          focused = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: focused
                ? const Color(0xFF6AE8BE).withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.10),
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: const Color(0xFF5DE2B0).withValues(alpha: 0.12),
                    blurRadius: 28,
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w600,
            letterSpacing: 12,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '• • • • • •',
            hintStyle: GoogleFonts.poppins(
              color: Colors.white24,
              fontSize: 20,
              letterSpacing: 5,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _GlowButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onPressed;

  const _GlowButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5DE2B0).withValues(alpha: 0.20),
              blurRadius: 25,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FilledButton(
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6AE8BE),
            disabledBackgroundColor: const Color(
              0xFF6AE8BE,
            ).withValues(alpha: 0.55),
            foregroundColor: const Color(0xFF063B2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: loading
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF063B2D),
                    ),
                  )
                : Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isHindi;
  final bool loading;
  final VoidCallback onPressed;

  const _GoogleButton({
    required this.isHindi,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
          backgroundColor: Colors.white.withValues(alpha: 0.045),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        'G',
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isHindi ? 'Google से जारी रखें' : 'Continue with Google',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white70,
        size: 19,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.055),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}

class _MiniLeaf extends StatelessWidget {
  const _MiniLeaf();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(58, 58), painter: _LeafPainter());
  }
}

// -----------------------------------------------------------------------------
// BACKGROUND
// -----------------------------------------------------------------------------

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF04152F),
                Color(0xFF082D4A),
                Color(0xFF063E3B),
                Color(0xFF041C2A),
              ],
            ),
          ),
        ),

        Positioned(
          top: -120,
          right: -80,
          child: _AmbientGlow(size: 320, color: const Color(0xFF45D9A4)),
        ),

        Positioned(
          bottom: -150,
          left: -100,
          child: _AmbientGlow(size: 360, color: const Color(0xFF1479A8)),
        ),

        CustomPaint(painter: _FieldLinesPainter()),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AmbientGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.13),
              blurRadius: 120,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAINTERS
// -----------------------------------------------------------------------------

class _LeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8BFFD2), Color(0xFF2DBF8A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.88)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.72,
        size.width * 0.15,
        size.height * 0.30,
        size.width * 0.52,
        size.height * 0.12,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.24,
        size.width * 0.84,
        size.height * 0.58,
        size.width * 0.5,
        size.height * 0.88,
      )
      ..close();

    canvas.drawPath(path, paint);

    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.82),
      Offset(size.width * 0.5, size.height * 0.22),
      vein,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _FieldLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7AE9C4).withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = -3; i < 9; i++) {
      final path = Path();

      path.moveTo(size.width * 0.05, size.height * (0.25 + i * 0.10));

      path.cubicTo(
        size.width * 0.35,
        size.height * (0.10 + i * 0.10),
        size.width * 0.65,
        size.height * (0.38 + i * 0.10),
        size.width * 1.05,
        size.height * (0.22 + i * 0.10),
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
