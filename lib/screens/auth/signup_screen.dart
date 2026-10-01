import 'package:flutter/material.dart';
import 'package:bridgewatercollege/widgets/custom_text_field.dart';
import 'package:bridgewatercollege/widgets/primary_button.dart';
import 'package:bridgewatercollege/widgets/auth_header.dart';
import 'package:bridgewatercollege/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _deptController = TextEditingController();
  final _yearController = TextEditingController();
  final _roomController = TextEditingController();
  bool _isLoading = false;

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Direct Table Insert (No auth.signUp)
        await Supabase.instance.client.from('profiles').insert({
          'full_name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'student_id': _idController.text.trim(),
          'password': _passController.text.trim(),
          'department': _deptController.text.trim(),
          'admission_year': int.tryParse(_yearController.text.trim()),
          'room_no': _roomController.text.trim(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created Successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
         if (!mounted) return;
         final msg = e.toString().contains('duplicate') || e.toString().contains('unique')
             ? 'This College ID or Email is already registered.'
             : 'Registration failed. Please check your details and try again.';
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(msg), backgroundColor: Colors.red)
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
          
          return SafeArea(
            child: Center(
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
                          const AuthHeader(
                            title: 'Create Account',
                            subtitle: 'Enter your credentials to join Bridgewater',
                          ),
                          SizedBox(height: isShort ? 20 : 32),
                        _buildTextFieldLabel('Full Name'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _nameController,
                          label: '',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldLabel('College ID'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _idController,
                          label: '',
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldLabel('Email Address'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _emailController,
                          label: '',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) => (!value!.contains('@')) ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 20),
                         _buildTextFieldLabel('Department'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _deptController,
                          label: '',
                          prefixIcon: Icons.business_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldLabel('Admission Year'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _yearController,
                          label: '',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldLabel('Room No.'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _roomController,
                          label: 'e.g. 301',
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.meeting_room_outlined,
                        ),
                        const SizedBox(height: 20),
                        _buildTextFieldLabel('Password'),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _passController,
                          label: '',
                          isPassword: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          validator: (value) => value!.length < 6 ? 'Min. 6 chars required' : null,
                        ),
                        const SizedBox(height: 40),
                        PrimaryButton(
                          text: 'Sign Up',
                          isLoading: _isLoading,
                          onPressed: _handleSignup,
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                                children: [
                                  const TextSpan(text: 'Already have an account? '),
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildTextFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
    );
  }
}
