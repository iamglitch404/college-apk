import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              '1. Acceptance of Terms',
              'By accessing and using the Bridgewater College Mobile Application, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions. If you do not agree, please do not use the application.',
            ),
            _buildSection(
              '2. Eligibility',
              'This application is exclusively for the students, faculty, and authorized staff of Bridgewater College. Access is granted based on valid institution-issued credentials.',
            ),
            _buildSection(
              '3. User Responsibilities',
              '• You are responsible for maintaining the confidentiality of your login credentials.\n'
              '• You agree not to share your account with anyone else.\n'
              '• You are responsible for all activities that occur under your account.\n'
              '• You must notify the IT department immediately of any security breaches.',
            ),
            _buildSection(
              '4. Academic Integrity & Conduct',
              'Students are expected to maintain the highest standards of academic integrity. Using the app to gain an unfair advantage, accessing unauthorized data, or falsifying academic records is strictly prohibited and subject to college disciplinary policies.',
            ),
            _buildSection(
              '5. Intellectual Property',
              'All content, including text, graphics, logos, and software, is the property of Bridgewater International College and is protected by copyright and intellectual property laws.',
            ),
            _buildSection(
              '6. AI Support Usage',
              'The Academic AI Support uses Mistral AI technology. While we strive for accuracy, the AI may occasionally provide incorrect information. Official decisions should always be based on information from college departments.',
            ),
            _buildSection(
              '7. Limitation of Liability',
              'The college is not liable for any direct, indirect, incidental, or consequential damages resulting from your use or inability to use the application, including data loss or service interruptions.',
            ),
            _buildSection(
              '8. Governing Law',
              'These terms shall be governed by and construed in accordance with the laws of Nepal and the internal policies of Bridgewater International College.',
            ),
            _buildSection(
              '9. Contact Information',
              'For questions regarding these terms, please contact: \nIT Support: support@bridgewater.edu.np\nRegistrar Office: registrar@bridgewater.edu.np',
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
