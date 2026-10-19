import 'dart:math' as math;
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
                          // Custom painted shield with heartbeat pulse
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CustomPaint(
                              painter: _CivicPulseEmblemPainter(
                                pulseProgress: _pulseWaveAnimation.value,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // Title: CIVICPULSE
                          Opacity(
                            opacity: _titleFadeAnimation.value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - _titleFadeAnimation.value)),
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
                              offset: Offset(0, 8 * (1 - _subtitleFadeAnimation.value)),
                              child: Text(
                                'SMART CITY CITIZEN PORTAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4.5,
                                  color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
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
                            color: AppColors.textSecondaryLight.withValues(alpha: 0.6),
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

/// Custom painter for the CivicPulse shield emblem and heartbeat pulse line
/// on a clean white background — uses brand teal + civic blue only.
class _CivicPulseEmblemPainter extends CustomPainter {
  final double pulseProgress;

  _CivicPulseEmblemPainter({required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Shield contour path
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, h * 0.06);
    shieldPath.quadraticBezierTo(w * 0.90, h * 0.10, w * 0.90, h * 0.44);
    shieldPath.cubicTo(w * 0.90, h * 0.72, w * 0.65, h * 0.89, w * 0.5, h * 0.95);
    shieldPath.cubicTo(w * 0.35, h * 0.89, w * 0.10, h * 0.72, w * 0.10, h * 0.44);
    shieldPath.quadraticBezierTo(w * 0.10, h * 0.10, w * 0.5, h * 0.06);
    shieldPath.close();

    // Shield fill — very subtle teal tint
    final shieldFillPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          const Color(0xFF0D9488).withValues(alpha: 0.08),
          const Color(0xFF1E3A8A).withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldFillPaint);

    // Shield stroke — clean gradient from teal to civic blue
    final shieldStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D9488), // Teal
          Color(0xFF1E3A8A), // Civic Blue
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldStrokePaint);

    // 2. Heartbeat / pulse wave line
    final pulsePath = Path();
    pulsePath.moveTo(w * 0.18, h * 0.52);
    pulsePath.lineTo(w * 0.34, h * 0.52);
    pulsePath.lineTo(w * 0.42, h * 0.34);
    pulsePath.lineTo(w * 0.50, h * 0.70);
    pulsePath.lineTo(w * 0.58, h * 0.26);
    pulsePath.lineTo(w * 0.66, h * 0.56);
    pulsePath.lineTo(w * 0.72, h * 0.52);
    pulsePath.lineTo(w * 0.82, h * 0.52);

    // Base line — very subtle
    final basePulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF1E3A8A).withValues(alpha: 0.12);
    canvas.drawPath(pulsePath, basePulsePaint);

    // 3. Animated pulse beam
    final pathMetrics = pulsePath.computeMetrics();
    for (final metric in pathMetrics) {
      final totalLen = metric.length;
      final headPos = totalLen * pulseProgress;
      final tailLen = totalLen * 0.45;
      final startPos = math.max(0.0, headPos - tailLen);

      if (headPos > 0) {
        final animatedSubPath = metric.extractPath(startPos, headPos);

        // Soft glow
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF0D9488).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawPath(animatedSubPath, glowPaint);

        // Core beam — teal gradient
        final beamPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = const LinearGradient(
            colors: [
              Color(0xFF1E3A8A), // Civic Blue
              Color(0xFF0D9488), // Teal
            ],
            stops: [0.0, 1.0],
          ).createShader(Rect.fromLTWH(0, 0, w, h));
        canvas.drawPath(animatedSubPath, beamPaint);

        // Leading dot at the tip
        final tangent = metric.getTangentForOffset(headPos);
        if (tangent != null && pulseProgress < 0.96) {
          final dotPaint = Paint()
            ..color = const Color(0xFF0D9488)
            ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
          canvas.drawCircle(tangent.position, 3.5, dotPaint);

          final auraPaint = Paint()
            ..color = const Color(0xFF0D9488).withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
          canvas.drawCircle(tangent.position, 7.0, auraPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CivicPulseEmblemPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress;
  }
}
