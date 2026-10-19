import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:civicpulse_app/core/constants/api_endpoints.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/features/auth/application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isGoogleLoading = false;
  bool _showEmailFallback = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerConfigDialog() {
    final serverController = TextEditingController(text: ApiEndpoints.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.dns_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Backend Server Connection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose a preset or type your PC\'s Wi-Fi / LAN address:',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.usb, size: 16),
                      label: const Text('USB (localhost)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text = 'http://localhost:8080/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.wifi, size: 16),
                      label: const Text('Wi-Fi (10.209.125.178)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text = 'http://10.209.125.178:8080/api/v1';
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.phone_android, size: 16),
                      label: const Text('Emulator (10.0.2.2)'),
                      onPressed: () {
                        setDialogState(() {
                          serverController.text = 'http://10.0.2.2:8080/api/v1';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: serverController,
                  decoration: InputDecoration(
                    labelText: 'Server Base URL',
                    hintText: 'http://10.209.125.178:8080/api/v1',
                    prefixIcon: const Icon(Icons.lan_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (serverController.text.trim().isNotEmpty) {
                  ApiEndpoints.setCustomBaseUrl(serverController.text.trim());
                  setState(() => _errorMessage = null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server updated to: ${ApiEndpoints.baseUrl}')),
                  );
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();

    // Check if running on web without custom Google Client ID
    const configuredClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
    if (kIsWeb && configuredClientId.isEmpty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              GoogleLogoWidget(size: 24),
              SizedBox(width: 12),
              Text('Google Citizen Sign-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A Google Cloud Console OAuth Client ID is required for real Google login on localhost. Without it, Google displays "Error 401: invalid_client".',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt, color: AppColors.primary, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Instant Verified Citizen Demo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            'Log in immediately as a verified citizen to test reporting and exploring issues.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('real'),
              child: const Text('Try Real Google Popup'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop('demo'),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Continue as Demo Citizen'),
            ),
          ],
        ),
      );

      if (choice == null) return;
      if (choice == 'demo') {
        setState(() {
          _errorMessage = null;
          _isGoogleLoading = true;
        });
        try {
          await ref.read(authControllerProvider.notifier).login(
            'citizen@civicpulse.city',
            'Citizen@123',
          );
          if (mounted) {
            context.go('/');
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = e.toString().replaceFirst('Exception: ', '');
              _showEmailFallback = true;
            });
          }
        } finally {
          if (mounted) {
            setState(() => _isGoogleLoading = false);
          }
        }
        return;
      }
    }

    setState(() {
      _errorMessage = null;
      _isGoogleLoading = true;
    });

    try {
      final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();
      if (success && mounted) {
        context.go('/');
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('popup_closed') ||
          errStr.contains('popup_closed_by_user') ||
          errStr.contains('access_denied') ||
          errStr.contains('cancelled') ||
          errStr.contains('canceled')) {
        // User closed or dismissed the popup — silence error
        return;
      }
      String msg = 'Google sign-in was unable to complete. Please try again.';
      if (errStr.contains('Null check operator') || errStr.contains('OAuth Client ID') || errStr.contains('GOOGLE_CLIENT_ID') || errStr.contains('invalid_client')) {
        msg = 'Google returned invalid_client. Register an OAuth Web Client ID in Google Cloud Console for http://localhost:5000, or use the demo options.';
      } else if (e is FormatException) {
        msg = e.message;
      } else if (e is DioException) {
        if (e.response?.statusCode == 401) {
          msg = 'Invalid Google credentials or unverified email address.';
        } else if (e.response?.statusCode == 403) {
          final detail = (e.response?.data is Map)
              ? (e.response!.data as Map)['detail']?.toString()
              : null;
          msg = detail ?? 'Access denied. Account is disabled or unauthorized.';
        } else if (e.response?.statusCode == 429) {
          msg = 'Too many attempts. Please wait a minute before retrying.';
        } else if (e.response?.data is Map && (e.response!.data as Map)['detail'] != null) {
          msg = (e.response!.data as Map)['detail'].toString();
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          msg = 'Cannot reach backend at ${ApiEndpoints.baseUrl}. Ensure server is running and accessible.';
        }
      } else {
        msg = errStr.replaceFirst('Exception: ', '').replaceFirst('FormatException: ', '');
      }
      if (mounted) {
        setState(() {
          _errorMessage = msg;
          _showEmailFallback = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);

    try {
      await ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      String msg = 'Invalid email or password. Please verify your credentials.';
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          msg = 'Invalid email or password. Please verify your credentials.';
        } else if (e.response?.statusCode == 429) {
          msg = 'Too many attempts. Please wait a minute before retrying.';
        } else if (e.response?.data is Map && (e.response!.data as Map)['detail'] != null) {
          msg = (e.response!.data as Map)['detail'].toString();
        } else if (e.response?.data is Map && (e.response!.data as Map)['errors'] != null) {
          final errs = (e.response!.data as Map)['errors'] as List;
          if (errs.isNotEmpty) msg = errs.first.toString();
        } else if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          msg = 'Cannot reach backend at ${ApiEndpoints.baseUrl}. Ensure mobile and PC are on the same network.';
        }
      }
      setState(() {
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isEmailLoading = authState.isLoading;
    final isAnyLoading = _isGoogleLoading || isEmailLoading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Server Settings (Backend IP)',
              onPressed: _showServerConfigDialog,
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Icon & Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_city_rounded,
                        size: 52,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CivicPulse',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Empowering Citizens • Transforming Cities',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Notification Banner
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.priorityCritical.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.priorityCritical.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.priorityCritical, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.priorityCritical, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ==========================================
                  // PRIMARY ACTION: CONTINUE WITH GOOGLE
                  // ==========================================
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Quick Citizen Sign-In',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: isAnyLoading ? null : _handleGoogleSignIn,
                            child: Ink(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF131314) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF8E918F) : const Color(0xFF747775),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isGoogleLoading) ...[
                                      const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Verifying with Google...',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ] else ...[
                                      const GoogleLogoWidget(size: 22),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No manual registration required. We automatically set up your verified Citizen account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Toggle for Email/Password fallback
                  TextButton.icon(
                    onPressed: () => setState(() => _showEmailFallback = !_showEmailFallback),
                    icon: Icon(
                      _showEmailFallback ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                    ),
                    label: Text(_showEmailFallback
                        ? 'Hide Municipal Credentials'
                        : 'Sign In with Email / Staff Credentials'),
                  ),

                  if (_showEmailFallback) ...[
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'citizen@civicpulse.city',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Sign In Button
                          ElevatedButton(
                            onPressed: isAnyLoading ? null : _handleLogin,
                            child: isEmailLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sign In with Email'),
                          ),
                          const SizedBox(height: 12),

                          // Sign Up Link (for users preferring email/password)
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Text("Need an account? Register with email"),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  // Quick Fill Hint for test accounts
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                          label: const Text('Test Citizen', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _showEmailFallback = true;
                              _emailController.text = 'citizen@civicpulse.city';
                              _passwordController.text = 'Citizen@123';
                            });
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.security, size: 16, color: AppColors.secondary),
                          label: const Text('Test Officer', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _showEmailFallback = true;
                              _emailController.text = 'officer@civicpulse.city';
                              _passwordController.text = 'Officer@123';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Official Google "G" multi-colored logo drawn via CustomPainter for crisp rendering on all screens
class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w * 0.45;
    final double strokeWidth = w * 0.22;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    // Red: Top arc
    final paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.5, false, paintRed);

    // Yellow: Left arc
    final paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, math.pi * 0.75, math.pi * 0.5, false, paintYellow);

    // Green: Bottom arc
    final paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.5, false, paintGreen);

    // Blue: Right arc & crossbar
    final paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, -math.pi * 0.25, math.pi * 0.5, false, paintBlue);

    // Crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTRB(cx - w * 0.05, cy - strokeWidth / 2, cx + radius + strokeWidth / 2, cy + strokeWidth / 2);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
