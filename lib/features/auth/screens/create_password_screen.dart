import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

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
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.isLogin ? 'Sign In' : 'Create Password',
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
              Text(
                widget.isLogin ? 'Enter password' : 'Set your password',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isLogin
                    ? 'Enter your password for ${widget.email} to sign in.'
                    : 'Create a strong password for ${widget.email} to secure your account.',
                style: GoogleFonts.poppins(
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
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF0D47A1),
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
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0D47A1),
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
                      color: Color(0xFF0D47A1),
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
              ],
              const SizedBox(height: 36),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
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
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isLogin ? 'Login & Continue' : 'Register & Continue',
                          style: GoogleFonts.poppins(
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
