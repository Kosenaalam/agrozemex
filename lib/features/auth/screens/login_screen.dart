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
  final TextEditingController phoneCtrl = TextEditingController();
  String? errorMessage; 
  bool isLoading = false; 
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone, 
              decoration: InputDecoration(
                labelText: 'Phone (+91XXXXXXXXXX)',
                errorText: errorMessage, 
                prefixIcon: const Icon(Icons.phone), 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), 
                ),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator(),)
                : ElevatedButton(
                    onPressed: () async {
                      final phone = phoneCtrl.text.trim();
                      if (!phone.startsWith('+91') || phone.length != 13) { 
                        setState(() {
                          errorMessage = 'Invalid phone number. Use +91 followed by 10 digits.';
                        });
                        return;
                      }
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      try {
                        await auth.sendOtp(
                          phone,
                          (id) => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OtpScreen(verificationId: id),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar( 
                          SnackBar(content: Text('Error sending OTP. Something is wrong')),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Send OTP', style: TextStyle(fontSize: 10)),
                  ),
          ],
        ),
      ),
    );
  }
}