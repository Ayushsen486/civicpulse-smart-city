import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';

/// A clean, white-themed splash screen with elegant minimalist animations.
/// Features a soft shield emblem reveal, teal heartbeat pulse sweep,
/// graceful brand typography entrance, and a smooth fade-out transition.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staged animation curves — longer and more deliberate
  late final Animation<double> _bgGlowAnimation;
  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoOpacityAnimation;
  late final Animation<double> _pulseWaveAnimation;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _taglineFadeAnimation;
  late final Animation<double> _exitFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Extended duration for a more premium feel
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    // 0.0 – 0.25: Soft ambient teal glow blooms from center
    _bgGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    // 0.05 – 0.30: Shield emblem fades in gently
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.30, curve: Curves.easeIn),
      ),
    );

    // 0.08 – 0.38: Shield scales up with elegant deceleration
    _logoScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.38, curve: Curves.easeOutCubic),
      ),
    );

    // 0.22 – 0.58: Heartbeat pulse sweeps across the shield
    _pulseWaveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.58, curve: Curves.easeInOutCubic),
      ),
    );

    // 0.40 – 0.60: Brand title fades and rises into view
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.60, curve: Curves.easeOut),
      ),
    );

    // 0.50 – 0.68: Subtitle gently appears below
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.68, curve: Curves.easeOut),
      ),
    );

    // 0.60 – 0.78: Bottom tagline fades in
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.78, curve: Curves.easeOut),
      ),
    );

    // 0.85 – 1.0: Entire screen fades out to white before navigation
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Trigger auth state evaluation in parallel
    ref.read(authControllerProvider);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final exitFade = _exitFadeAnimation.value;

          return Opacity(
            opacity: exitFade,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Soft radial teal glow on white backdrop
                Positioned.fill(
                  child: Opacity(
                    opacity: _bgGlowAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: [
                            AppColors.secondary.withValues(alpha: 0.06),
                            AppColors.primary.withValues(alpha: 0.03),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Center: Shield emblem + brand typography
                Center(
                  child: Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Official CivicPulse App Logo with elevation and gentle pulse glow
                          Container(
                            width: 135,
                            height: 135,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha:
                                        0.18 + 0.12 * _pulseWaveAnimation.value,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(32),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Title: CIVICPULSE
                          Opacity(
                            opacity: _titleFadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                10 * (1 - _titleFadeAnimation.value),
                              ),
                              child: const Text(
                                'CIVICPULSE',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 10.0,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle: SMART CITY CITIZEN PORTAL
                          Opacity(
                            opacity: _subtitleFadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(
                                0,
                                8 * (1 - _subtitleFadeAnimation.value),
                              ),
                              child: Text(
                                'SMART CITY CITIZEN PORTAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4.5,
                                  color: AppColors.textSecondaryLight
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Elegant thin divider
                          Opacity(
                            opacity: _subtitleFadeAnimation.value,
                            child: Container(
                              width: 48,
                              height: 2,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.secondary,
                                    AppColors.primary,
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

                // 3. Bottom: Secure network tagline
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _taglineFadeAnimation.value * 0.7,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.statusResolved,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SECURE MUNICIPAL NETWORK',
                          style: TextStyle(
                            color: AppColors.textSecondaryLight.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ),
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
