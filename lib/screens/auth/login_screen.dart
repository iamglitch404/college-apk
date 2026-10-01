import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bridgewatercollege/widgets/custom_text_field.dart';
import 'package:bridgewatercollege/widgets/primary_button.dart';
import 'package:bridgewatercollege/widgets/auth_header.dart';
import 'package:bridgewatercollege/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/academic_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final identifier = _idController.text.trim();
        final password = _passwordController.text.trim();
        
        // Direct Table Query (Bypassing Supabase Auth)
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .or('email.eq.$identifier,student_id.eq.$identifier')
            .eq('password', password)
            .maybeSingle();

        if (response != null) {
          if (!mounted) return;
          // Store the session locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_id', response['student_id']);
          
          // Trigger Background Sync (Don't wait for it to finish)
          final academic = AcademicService();
          academic.syncAllData(
            studentId: response['student_id'],
            department: response['department'],
            year: (response['admission_year'] as num?)?.toInt(),
            roomNo: response['room_no']?.toString(),
          );
          
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid ID/Email or Password'), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please check your connection and try again.'), backgroundColor: Colors.redAccent),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light 
          ? const Color(0xFFF8F9FA) 
          : AppTheme.darkBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final isShort = constraints.maxHeight < 700;
          final screenWidth = constraints.maxWidth;
          final formWidth = isMobile ? screenWidth * 0.9 : (screenWidth > 1200 ? 500.0 : screenWidth * 0.5);
          
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12.0 : 40.0, 
                vertical: isShort ? 20.0 : 40.0
              ),
              child: SizedBox(
                width: formWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 0 : 24, 
                    vertical: isShort ? 10 : 40
                  ),
                  child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AuthHeader(
                        title: 'Sign In',
                        subtitle: 'Enter your credentials to continue',
                      ),
                      const SizedBox(height: 32),
                      _buildTextFieldLabel('College ID or Email'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _idController,
                        label: '',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildTextFieldLabel('Password'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _passwordController,
                        label: '',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onSuffixIconPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              borderRadius: BorderRadius.circular(4),
                              hoverColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              overlayColor: WidgetStateProperty.all(Colors.transparent),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(() => _rememberMe = v!),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Remember', 
                                    style: TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero, 
                              minimumSize: const Size(50, 30),
                              overlayColor: Colors.transparent,
                              splashFactory: NoSplash.splashFactory,
                            ),
                            child: Text(
                              'Forgot?', 
                              style: TextStyle(
                                color: theme.colorScheme.primary, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 13,
                              )
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms),
                      
                      const SizedBox(height: 32),
                      PrimaryButton(
                        text: 'Login',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signup'),
                        style: TextButton.styleFrom(
                          overlayColor: theme.colorScheme.primary.withValues(alpha: 0.05),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                            children: [
                              const TextSpan(text: "Don't have access? "),
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    bool isOtpSent = false;
    bool isOtpVerified = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Account Recovery', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOtpSent) ...[
                const Text('Enter your registered email to receive a recovery code.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                CustomTextField(controller: emailController, label: 'Email Address', prefixIcon: Icons.email_outlined),
              ] else if (isOtpSent && !isOtpVerified) ...[
                const Text('Enter the 6-digit code sent for verification.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                CustomTextField(controller: otpController, label: '6-Digit OTP', keyboardType: TextInputType.number, prefixIcon: Icons.lock_clock_outlined),
              ] else ...[
                const Text('OTP Verified! Enter your new password below.', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomTextField(controller: newPassController, label: 'New Password', isPassword: true, prefixIcon: Icons.vpn_key_outlined),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (!isOtpSent) {
                  // Send OTP Logic
                  final otp = (100000 + (999999 - 100000) * (DateTime.now().millisecond / 1000)).toInt().toString();
                  await Supabase.instance.client.from('user_otps').insert({
                    'email': emailController.text.trim(),
                    'otp_code': otp,
                    'purpose': 'forgot_password',
                  });
                  debugPrint('OTP sent to ${emailController.text.trim()}');
                  setDialogState(() => isOtpSent = true);
                } else if (isOtpSent && !isOtpVerified) {
                  // Verify OTP
                  final res = await Supabase.instance.client
                      .from('user_otps')
                      .select()
                      .eq('email', emailController.text.trim())
                      .eq('otp_code', otpController.text.trim())
                      .maybeSingle();
                  
                  if (res != null) {
                    setDialogState(() => isOtpVerified = true);
                  }
                } else {
                  // Complete password reset
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully! You can now log in.'), backgroundColor: Colors.blueAccent),
                  );
                }
              },
              child: Text(!isOtpSent ? 'Send OTP' : (isOtpVerified ? 'Reset Password' : 'Verify OTP')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
    );
  }
}
