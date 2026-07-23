import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';

class PhoneBindingDialog extends StatefulWidget {
  const PhoneBindingDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PhoneBindingDialog(),
    );
    return result ?? false;
  }

  @override
  State<PhoneBindingDialog> createState() => _PhoneBindingDialogState();
}

class _PhoneBindingDialogState extends State<PhoneBindingDialog> {
  final TextEditingController _phoneCtrl = TextEditingController();
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
  void dispose() {
    _phoneCtrl.dispose();
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

  Future<void> _sendOtp() async {
    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please accept Terms & Conditions to proceed.');
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
    final otp = _otpDigitCtrls.map((c) => c.text.trim()).join();
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
      final fullPhone = _countryCode + _phoneCtrl.text.trim();
      final auth = context.read<AuthService>();
      await auth.linkOrUpdateUserPhoneWithOtp(_verificationId!, otp, fullPhone);
      if (mounted) {
        Navigator.pop(context, true);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phone Verification Required',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AgroZemexTokens.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'To view listing details and contact sellers, please bind your phone number and accept contact inquiry terms.',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: GoogleFonts.inter(color: Colors.red[800], fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (!_isOtpSent) ...[
            Row(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryCode,
                      items: const [
                        DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                        DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                        DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _countryCode = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    activeColor: AgroZemexTokens.primary,
                    onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I agree to Terms & Privacy Policy and consent to sharing my phone number with land/crop sellers for inquiries.',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AgroZemexTokens.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Send OTP Code'),
                    ),
                  ),
          ] else ...[
            Text(
              'Enter 6-digit code sent to $_countryCode ${_phoneCtrl.text}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 42,
                  height: 48,
                  child: TextField(
                    controller: _otpDigitCtrls[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (val) {
                      if (val.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (val.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AgroZemexTokens.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Verify Phone & Unlock Details'),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}
