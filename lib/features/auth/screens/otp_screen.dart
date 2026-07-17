import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpCtrl = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'OTP',
                errorText: errorMessage,
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () async {
                      final otp = otpCtrl.text.trim();
                      if (otp.length != 6) {
                        setState(() => errorMessage = 'Enter a 6-digit OTP.');
                        return;
                      }
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      try {
                        await auth.verifyOtp(widget.verificationId, otp);
                        if (context.mounted) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                        }
                          
                        
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            errorMessage = e.toString().contains('invalid-verification-code')
                                ? 'Invalid OTP. Please try again.'
                                : 'Error: Something is wrong';
                          });
                        }
                      } finally {
                        if (mounted) setState(() => isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                    ),
                    child: const Text('Verify OTP', style: TextStyle(fontSize: 16)),
                  ),
          ],
        ),
      ),
    );
  }
}