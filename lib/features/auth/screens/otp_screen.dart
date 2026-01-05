import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class OtpScreen extends StatelessWidget {
  final String verificationId;
  const OtpScreen({super.key, required this.verificationId});

  @override
  Widget build(BuildContext context) {
    final otpCtrl = TextEditingController();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: otpCtrl,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await auth.verifyOtp(verificationId, otpCtrl.text);
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
