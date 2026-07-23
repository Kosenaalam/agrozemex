import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'package:agrozemex/core/theme/theme.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String email;
  final bool isLogin;
  const CreatePasswordScreen({
    super.key,
    required this.email,
    this.isLogin = false,
  });

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.isLogin ? 'Sign In' : 'Create Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AgroZemexTokens.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isLogin ? 'Enter password' : 'Set your password',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AgroZemexTokens.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isLogin
                    ? 'Enter your password for ${widget.email} to sign in.'
                    : 'Create a strong password for ${widget.email} to secure your account.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 36),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: AgroZemexTokens.radiusTwelve,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
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
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AgroZemexTokens.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AgroZemexTokens.radiusTwelve,
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AgroZemexTokens.radiusTwelve,
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AgroZemexTokens.radiusTwelve,
                    borderSide: const BorderSide(
                      color: AgroZemexTokens.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (widget.isLogin) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      try {
                        await auth.sendPasswordResetEmail(widget.email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Password reset link sent to ${widget.email}. Please check your inbox.',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _errorMessage = e.toString());
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    child: Text(
                      'Forgot Password? / Login with OTP',
                      style: GoogleFonts.inter(
                        color: AgroZemexTokens.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
              if (!widget.isLogin) ...[
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AgroZemexTokens.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPass = !_obscureConfirmPass,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AgroZemexTokens.radiusTwelve,
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AgroZemexTokens.radiusTwelve,
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AgroZemexTokens.radiusTwelve,
                      borderSide: const BorderSide(
                        color: AgroZemexTokens.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
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
                    child: Text(
                      'I agree to the Terms & Conditions and Privacy Policy, and consent to sharing my registered contact phone number with sellers/buyers for inquiries.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
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
                        onPressed: () async {
                          if (!_agreedToTerms) {
                            setState(
                              () => _errorMessage = 'Please accept Terms & Conditions and Privacy Policy to proceed.',
                            );
                            return;
                          }
                          final pass = _passCtrl.text.trim();
                          final confirmPass = _confirmPassCtrl.text.trim();

                          if (pass.isEmpty || (!widget.isLogin && confirmPass.isEmpty)) {
                            setState(
                              () => _errorMessage = 'All fields are required.',
                            );
                            return;
                          }
                          if (pass.length < 6) {
                            setState(
                              () => _errorMessage =
                                  'Password must be at least 6 characters.',
                            );
                            return;
                          }
                          if (!widget.isLogin && pass != confirmPass) {
                            setState(
                              () => _errorMessage = 'Passwords do not match.',
                            );
                            return;
                          }

                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });

                          try {
                            if (widget.isLogin) {
                              await auth.signInWithEmailAndPassword(
                                widget.email,
                                pass,
                              );
                            } else {
                              await auth.registerWithEmailAndPassword(
                                widget.email,
                                pass,
                              );
                            }
                            if (context.mounted) {
                              Navigator.popUntil(
                                context,
                                (route) => route.isFirst,
                              );
                            }
                          } on AuthException catch (e) {
                            if (mounted) {
                              setState(() {
                                if (e.code == 'user-exists') {
                                  _errorMessage =
                                      'An account already exists with this email address. Please login instead.';
                                } else {
                                  _errorMessage = e.message;
                                }
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _errorMessage = e.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                );
                              });
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AgroZemexTokens.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: AgroZemexTokens.radiusTwelve,
                          ),
                        ),
                        child: Text(
                          widget.isLogin ? 'Login & Continue' : 'Register & Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
