import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/create_password_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? initialPhone;
  const LoginScreen({super.key, this.initialPhone});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();

  final List<TextEditingController> _otpDigitCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String _countryCode = '+91';
  bool _isOtpSent = false;
  bool _agreedToTerms = false;
  String? _verificationId;
  int? _resendToken;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _timer;
  int _countdownSeconds = 30;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      String rawPhone = widget.initialPhone!;
      if (rawPhone.startsWith('+91')) {
        _countryCode = '+91';
        _phoneCtrl.text = rawPhone.replaceFirst('+91', '');
      } else if (rawPhone.startsWith('+')) {
        _phoneCtrl.text = rawPhone;
      } else {
        _phoneCtrl.text = rawPhone;
      }
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    for (final ctrl in _otpDigitCtrls) {
      ctrl.dispose();
    }
    for (final node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdownSeconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _showEmailInputDialog(BuildContext context) {
    final TextEditingController emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Enter Email',
            style: AgroZemexTokens.headlineMedium.copyWith(color: AgroZemexTokens.primary),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'name@example.com',
                labelStyle: AgroZemexTokens.bodyMedium,
                border: OutlineInputBorder(
                  borderRadius: AgroZemexTokens.radiusEight,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AgroZemexTokens.radiusEight,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AgroZemexTokens.bodyMedium.copyWith(color: AgroZemexTokens.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AgroZemexTokens.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AgroZemexTokens.radiusEight,
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final email = emailCtrl.text.trim();
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreatePasswordScreen(email: email, isLogin: true),
                    ),
                  );
                }
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _syncOtpFromDigits() {
    _otpCtrl.text = _otpDigitCtrls.map((c) => c.text).join();
  }

  void _clearOtpDigits() {
    for (final c in _otpDigitCtrls) {
      c.clear();
    }
    _otpCtrl.clear();
  }

  void _showLegalDialog(BuildContext context, {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: AgroZemexTokens.headlineMedium.copyWith(color: AgroZemexTokens.primary)),
        content: SingleChildScrollView(
          child: Text(content, style: AgroZemexTokens.bodyLarge),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOtp() async {
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please accept Terms & Conditions and Privacy Policy to proceed.');
      return;
    }
    final rawNumber = _phoneCtrl.text.trim();
    if (rawNumber.isEmpty || rawNumber.length < 7) {
      setState(() => _errorMessage = 'Please enter a valid phone number.');
      return;
    }

    final fullPhone = _countryCode + rawNumber;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthService>();
    await auth.sendOtp(
      phone: fullPhone,
      forceResendingToken: _resendToken,
      onCodeSent: (id, token) {
        if (!mounted) return;
        setState(() {
          _verificationId = id;
          _resendToken = token;
          _isOtpSent = true;
          _isLoading = false;
        });
        _startTimer();
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _errorMessage = err;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _verifyOtp() async {
    _syncOtpFromDigits();
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP.');
      return;
    }
    if (_verificationId == null) {
      setState(() => _errorMessage = 'Session invalid. Please resend OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nav = Navigator.of(context);
      final auth = context.read<AuthService>();
      await auth.verifyOtp(_verificationId!, otp);
      if (mounted) {
        nav.popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please accept Terms & Conditions and Privacy Policy to proceed.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = context.read<AuthService>();
      await auth.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _appleSignIn() async {
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please accept Terms & Conditions and Privacy Policy to proceed.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = context.read<AuthService>();
      await auth.signInWithApple();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 768;

    return Scaffold(
      backgroundColor: AgroZemexTokens.surface,
      body: Stack(
        children: [
          // PERF FIX: Wrapped in RepaintBoundary so that form field rebuilds,
          // error message changes, OTP transitions do NOT repaint this expensive
          // network image. Previously it was re-decoded on every setState() call.
          if (!_isOtpSent)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: isDesktop ? screenSize.height : screenSize.height * 0.55,
              child: RepaintBoundary(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      AppAssets.loginHero,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AgroZemexTokens.primary.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                    // Mobile Top Branding Overlay
                    Positioned(
                      top: 48,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'AgroZemex',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -1.0,
                            shadows: const [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Main Card & Interactive Content Container
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 480),
                  margin: EdgeInsets.only(
                    top: _isOtpSent ? 40 : screenSize.height * 0.40,
                    bottom: isDesktop && !_isOtpSent ? 48 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: AgroZemexTokens.surface,
                    borderRadius: _isOtpSent
                        ? BorderRadius.zero
                        : const BorderRadius.vertical(top: Radius.circular(32)),
                    border: _isOtpSent
                        ? null
                        : Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                    boxShadow: _isOtpSent
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 60,
                              offset: const Offset(0, -10),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AgroZemexTokens.marginMobile,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button Header for OTP mode
                      if (_isOtpSent) ...[
                        Row(
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.8),
                              shape: const CircleBorder(),
                              elevation: 1,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  setState(() {
                                    _isOtpSent = false;
                                    _clearOtpDigits();
                                    _errorMessage = null;
                                  });
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: AgroZemexTokens.primary,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'AgroZemex',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: AgroZemexTokens.primary.withValues(alpha: 0.2),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Error Banner
                      if (_errorMessage != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            borderRadius: AgroZemexTokens.radiusEight,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AgroZemexTokens.bodyLarge.copyWith(
                                    color: Colors.red[800],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (!_isOtpSent) ...[
                        // --- PHONE LOGIN INITIAL VIEW (HTML Snippet 1) ---
                        Text(
                          'Welcome to AgroZemex',
                          style: AgroZemexTokens.headlineMedium.copyWith(
                            fontSize: 24,
                            color: AgroZemexTokens.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure your agricultural assets with professional precision.',
                          style: AgroZemexTokens.bodyLarge.copyWith(
                            color: AgroZemexTokens.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Phone input group
                        Text(
                          'PHONE NUMBER',
                          style: AgroZemexTokens.labelCaps.copyWith(
                            color: AgroZemexTokens.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              height: 56,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: AgroZemexTokens.surfaceContainerLow,
                                border: Border.all(
                                  color: AgroZemexTokens.surfaceContainerLow,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _countryCode,
                                  items: const [
                                    DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                                    DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _countryCode = val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                style: AgroZemexTokens.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  hintText: '000 000 0000',
                                  fillColor: AgroZemexTokens.surfaceContainerLow,
                                  filled: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Mandatory Terms & Privacy Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: AgroZemexTokens.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _agreedToTerms = val ?? false;
                                    if (_agreedToTerms) _errorMessage = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Wrap(
                                children: [
                                  Text(
                                    'I agree to the ',
                                    style: AgroZemexTokens.bodyMedium.copyWith(fontSize: 12),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showLegalDialog(
                                      context,
                                      title: 'Terms & Conditions',
                                      content: 'Welcome to AgroZemex. By registering or using our platform, you agree to list genuine agricultural property or crops, maintain accurate contact details, and consent to allow interested sellers and buyers to view your registered contact number to initiate purchase/inquiry calls.',
                                    ),
                                    child: Text(
                                      'Terms & Conditions',
                                      style: AgroZemexTokens.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: AgroZemexTokens.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' & ',
                                    style: AgroZemexTokens.bodyMedium.copyWith(fontSize: 12),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showLegalDialog(
                                      context,
                                      title: 'Privacy Policy',
                                      content: 'AgroZemex prioritizes your data privacy. Your contact details are stored securely. By agreeing, you authorize AgroZemex to display your phone number exclusively to verified land and crop marketplace users for transaction inquiries.',
                                    ),
                                    child: Text(
                                      'Privacy Policy',
                                      style: AgroZemexTokens.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: AgroZemexTokens.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '. Sellers/buyers can view your phone number for inquiries.',
                                    style: AgroZemexTokens.bodyMedium.copyWith(
                                      fontSize: 12,
                                      color: AgroZemexTokens.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Send OTP Button
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _sendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AgroZemexTokens.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Send OTP',
                                        style: AgroZemexTokens.bodyLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.arrow_forward,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                        const SizedBox(height: 32),

                        // Divider (Or continue with)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.2),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  fontSize: 11,
                                  color: AgroZemexTokens.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.2),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Social Buttons Grid (Google & Apple)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _googleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AgroZemexTokens.surfaceContainerLow,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Google',
                                        style: AgroZemexTokens.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: _appleSignIn,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AgroZemexTokens.surfaceContainerLow,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.apple, size: 24, color: Colors.black),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Apple',
                                        style: AgroZemexTokens.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Footer Link
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              _showEmailInputDialog(context);
                            },
                            icon: const Icon(
                              Icons.email_outlined,
                              size: 18,
                              color: AgroZemexTokens.primary,
                            ),
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Login with Email instead',
                                  style: AgroZemexTokens.bodyLarge.copyWith(
                                    color: AgroZemexTokens.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AgroZemexTokens.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // --- OTP VERIFICATION VIEW (HTML Snippet 2) ---
                        Text(
                          'Verify Phone',
                          style: AgroZemexTokens.displayLarge.copyWith(
                            color: AgroZemexTokens.primary,
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: AgroZemexTokens.bodyLarge.copyWith(
                              color: AgroZemexTokens.onSurfaceVariant,
                              fontSize: 16,
                            ),
                            children: [
                              const TextSpan(text: 'Enter the 6-digit code sent to '),
                              TextSpan(
                                text: '$_countryCode ${_phoneCtrl.text.trim()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AgroZemexTokens.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 50,
                              height: 56,
                              child: TextField(
                                controller: _otpDigitCtrls[index],
                                focusNode: _otpFocusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AgroZemexTokens.primary,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AgroZemexTokens.surfaceContainerLow,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AgroZemexTokens.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val.isNotEmpty) {
                                    if (index < 5) {
                                      _otpFocusNodes[index + 1].requestFocus();
                                    }
                                  } else {
                                    if (index > 0) {
                                      _otpFocusNodes[index - 1].requestFocus();
                                    }
                                  }
                                  _syncOtpFromDigits();
                                },
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_countdownSeconds > 0) ...[
                              const Icon(
                                Icons.schedule,
                                size: 18,
                                color: AgroZemexTokens.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Resend in ',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  fontSize: 12,
                                  color: AgroZemexTokens.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '0:${_countdownSeconds < 10 ? '0' : ''}$_countdownSeconds',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  fontSize: 12,
                                  color: AgroZemexTokens.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else ...[
                              TextButton(
                                onPressed: _sendOtp,
                                child: Text(
                                  'RESEND CODE',
                                  style: AgroZemexTokens.labelCaps.copyWith(
                                    fontSize: 12,
                                    color: AgroZemexTokens.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isOtpSent = false;
                                  _clearOtpDigits();
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                'CHANGE NUMBER',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  fontSize: 12,
                                  color: AgroZemexTokens.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Container(
                          width: double.infinity,
                          height: 192,
                          decoration: BoxDecoration(
                            borderRadius: AgroZemexTokens.radiusLargeCard,
                            boxShadow: AgroZemexTokens.softShadows,
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuAxQnQlZ_ewJfiFhiDgKgO-xB6NGxk9K43rJyVYjhx_H4KbmOaqdz_mRPyKxz_0i0Onq5ymms3BDD0m69NPkFeZxt-Wqy8G7psqmBCmA71Ix4ycKZ4w8ik02yXSrFF-GdCYvSrF_ssILSyzqRHPVpxkHP8w3HmY9NvcB8M1tAnTOKgkeXnrsRcxCRVbXZWfrH3GgwED4MHRkY8Rt5ImurBuA8QKoOoSZAexcl4UQlhORP0VL9ZzXOgxKA',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: AgroZemexTokens.radiusLargeCard,
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AgroZemexTokens.primary.withValues(alpha: 0.85),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SECURED BY',
                                      style: AgroZemexTokens.labelCaps.copyWith(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'LandGuard™',
                                      style: AgroZemexTokens.headlineMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.white.withValues(alpha: 0.2),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.verified_user,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _verifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AgroZemexTokens.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 6,
                                    shadowColor: AgroZemexTokens.primary.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Verify & Proceed',
                                        style: AgroZemexTokens.bodyLarge.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            'By continuing, you agree to AgroZemex\nTerms of Service and Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: AgroZemexTokens.bodyLarge.copyWith(
                              fontSize: 12,
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

