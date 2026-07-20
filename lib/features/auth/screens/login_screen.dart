import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  String _countryCode = '+91';
  bool _isOtpSent = false;
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

  Future<void> _sendOtp() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isOtpSent ? 'Verify OTP' : 'Phone Sign In',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1A0D47A1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFF0D47A1),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isOtpSent ? 'Verify Phone OTP' : 'Welcome to AgroZemex',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpSent
                    ? 'Enter the 6-digit code sent to $_countryCode ${_phoneCtrl.text.trim()}'
                    : 'Enter your mobile number to sign in or create an account with OTP.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red[800],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (!_isOtpSent) ...[
                Row(
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
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
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: 'Mobile Number',
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Color(0xFF0D47A1),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0D47A1),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Send OTP',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ] else ...[
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                    color: const Color(0xFF0D47A1),
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: '6-Digit OTP Code',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF0D47A1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isOtpSent = false;
                          _otpCtrl.clear();
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: Text(
                        'Change Number',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D47A1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _countdownSeconds == 0 ? _sendOtp : null,
                      child: Text(
                        _countdownSeconds > 0
                            ? 'Resend OTP (${_countdownSeconds}s)'
                            : 'Resend OTP',
                        style: GoogleFonts.poppins(
                          color: _countdownSeconds == 0
                              ? const Color(0xFF0D47A1)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Verify & Sign In',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
