import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';
import 'package:agrozemex/core/theme/theme.dart';

/// AgroZemex Splash Screen built strictly from HTML/Tailwind specifications.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _bgScaleAnimation;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _dividerOpacity;
  late Animation<double> _footerOpacity;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Subtle scale animation for full bleed background (1.1 -> 1.0)
    _bgScaleAnimation = Tween<double>(begin: 1.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Logo section animation (delay: 300ms -> interval 0.1 to 0.45)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.1, 0.45, curve: Curves.easeOutCubic),
          ),
        );

    // Brand title animation (delay: 500ms -> interval 0.166 to 0.55)
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.166, 0.55, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.166, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    // Tagline animation (delay: 700ms -> interval 0.233 to 0.65)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.233, 0.65, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.233, 0.65, curve: Curves.easeOutCubic),
          ),
        );

    // Decorative divider animation (delay: 1200ms -> interval 0.4 to 0.8)
    _dividerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Footer animation (delay: 1500ms -> interval 0.5 to 0.9)
    _footerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });

    _controller.forward();
  }

  Future<void> _navigateToNextScreen() async {
    if (_hasNavigated || !mounted) return;

    final auth = context.read<AuthService>();
    if (auth.isLoading) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return auth.isLoading && mounted;
      });
    }

    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final currentUser = auth.user ?? FirebaseAuth.instance.currentUser;

    Widget targetScreen;
    if (currentUser != null) {
      targetScreen = const MainNavigationShell();
    } else {
      final savedPhone = await auth.getSavedPhoneFromPrefs();
      targetScreen = LoginScreen(initialPhone: savedPhone ?? '');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1C1C),
      body: GestureDetector(
        onTap: _navigateToNextScreen,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Full-Bleed Cinematic Background Canvas
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _bgScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bgScaleAnimation.value,
                    child: child,
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(AppAssets.loginHero, fit: BoxFit.cover),
                    // Soft Dark Overlay for Contrast with 2px blur
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x661A1C1C), // rgba(26, 28, 28, 0.4)
                              Color(0x991A1C1C), // rgba(26, 28, 28, 0.6)
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content Container
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 64.0 : 20.0,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo Section (slide-up + opacity)
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoOpacity.value,
                            child: FractionalTranslation(
                              translation: _logoSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          width: isDesktop ? 128 : 96,
                          height: isDesktop ? 128 : 96,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 25,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                  child: Image.asset(
                                    'assets/icons/app_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32), // mb-8
                      // Brand Name
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _titleOpacity.value,
                            child: FractionalTranslation(
                              translation: _titleSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          'AgroZemex',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 48.0 : 36.0,
                            height: isDesktop ? 1.1 : 1.2,
                            letterSpacing: isDesktop
                                ? 48.0 * -0.03
                                : 36.0 * -0.02,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16), // mb-4
                      // Tagline
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _taglineOpacity.value,
                            child: FractionalTranslation(
                              translation: _taglineSlide.value,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          "INVEST IN THE EARTH'S FOUNDATION.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 18.0,
                            height: 1.6,
                            letterSpacing: 18.0 * 0.1,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                      // Decorative Pacing Element
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _dividerOpacity.value,
                            child: child,
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            top: 80.0,
                          ), // mt-section-gap (80px)
                          height: 64.0, // h-16
                          width: 1.0, // w-px
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.5),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Aesthetic
            Positioned(
              bottom: 48.0, // bottom-12 (48px)
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(opacity: _footerOpacity.value, child: child);
                },
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'AGRICULTURAL ASSET CLASS',
                        style: GoogleFonts.inter(
                          fontSize: 10.0,
                          letterSpacing: 2.0, // 0.2em
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 4.0,
                        height: 4.0,
                        decoration: const BoxDecoration(
                          color: Color(0x33FFFFFF), // bg-white/20
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'INSTITUTIONAL PRECISION',
                        style: GoogleFonts.inter(
                          fontSize: 10.0,
                          letterSpacing: 2.0, // 0.2em
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
