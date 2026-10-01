import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: April 2024',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'By using the Bridgewater College application, you consent to our privacy and data practices. We are committed to protecting your personal information and ensuring transparency in how we collect and use it.',
            ),
            _buildSection(
              '2. Information Collection',
              '• Profile Information: We collect your name, ID, and email address as part of your college record.\n'
              '• Academic Records: The application displays information about your results, attendance, and assignments.\n'
              '• Usage Data: We track login frequency and feature usage to improve the app performance.\n'
              '• Device Information: We collect device type and OS version for technical support.',
            ),
            _buildSection(
              '3. How We Use Your Data',
              'Your data is processed to: \n'
              '• Manage and display your personal academic dashboard.\n'
              '• Send notifications about college deadlines and results.\n'
              '• Facilitate the IT support ticketing system.\n'
              '• Provide AI-driven academic assistance.',
            ),
            _buildSection(
              '4. Data & Privacy Protection',
              'We employ strict security measures to protect your data, including end-to-end encryption for all information transmitted between the app and our secure college servers.',
            ),
            _buildSection(
              '5. Shared Data & Third Parties',
              '• We do not sell your personal data to any third parties.\n'
              '• The Academic AI Support (Mistral AI) processes only your academic queries and does not have access to your personal academic records.\n'
              '• Technical support tickets may be shared with authorized IT staff for resolution.',
            ),
            _buildSection(
              '6. User Access Rights',
              'You have the right to access and review your personal data stored in the app. For corrections to your official college record, please visit the registrar office.',
            ),
            _buildSection(
              '7. Security Precautions',
              'You are responsible for not sharing your device or account password. Always log out from public or shared devices to maintain data privacy.',
            ),
            _buildSection(
              '8. Updates to Policy',
              'This Privacy Policy may be updated periodically. Notice of significant changes will be sent via app notification or an announcement on the Dashboard.',
            ),
            _buildSection(
              '9. Contact',
              'If you have concerns about your privacy, contact our data protection team: \nPrivacy Compliance: privacy@bridgewater.edu.np',
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}
