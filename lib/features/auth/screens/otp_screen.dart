import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final VoidCallback onSuccess;
  
  const OtpScreen({
    super.key,
    required this.email,
    required this.onSuccess,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Verification Code', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter OTP',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit verification code to ${widget.email}. Enter it below.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Note: For developer testing, the OTP code is printed to your IDE\'s debug/run console.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0D47A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
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
                          style: GoogleFonts.poppins(color: Colors.red[800], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.poppins(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: '6-Digit Code',
                  labelStyle: GoogleFonts.poppins(fontSize: 14, letterSpacing: 0, fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.security, color: Color(0xFF0D47A1)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final otp = _otpCtrl.text.trim();
                          if (otp.length != 6) {
                            setState(() => _errorMessage = 'Please enter a 6-digit code.');
                            return;
                          }
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });

                          try {
                            final success = await auth.verifySimulatedEmailOtp(widget.email, otp);
                            if (success) {
                              widget.onSuccess();
                            } else {
                              setState(() {
                                _errorMessage = 'Invalid OTP. Please check the developer console for the printed code.';
                              });
                            }
                          } catch (e) {
                            setState(() {
                              _errorMessage = 'An error occurred during verification.';
                            });
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Verify OTP',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                            _otpCtrl.clear();
                          });
                          try {
                            await auth.sendSimulatedEmailOtp(widget.email);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('A new OTP has been printed to the developer console.')),
                              );
                            }
                          } catch (e) {
                            setState(() => _errorMessage = 'Failed to resend OTP.');
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                  child: Text(
                    'Resend Verification Code',
                    style: GoogleFonts.poppins(color: const Color(0xFF0D47A1), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}