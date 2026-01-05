import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone (+91XXXXXXXXXX)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                auth.sendOtp(
                  phoneCtrl.text.trim(),
                  (id) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpScreen(verificationId: id),
                    ),
                  ),
                );
              },
              child: const Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
