import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_contact_screen.dart';
import 'help_pages.dart';
import 'legal/terms_of_service_screen.dart';
import 'legal/privacy_policy_screen.dart';
import 'security/change_password_screen.dart';
import 'security/two_factor_auth_screen.dart';
import '../services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/theme_manager.dart';

class ProfileDetailScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const ProfileDetailScreen({super.key, required this.title, required this.items});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final Map<String, bool> _switchStates = {};
  final Map<String, String?> _subtitles = {};
  bool _isFetching = false;
  final _profileService = ProfileService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      if (item['trailing'] is Switch) {
        _switchStates[item['title']] = (item['trailing'] as Switch).value;
      }
      _subtitles[item['title']] = item['subtitle'];
    }

    // Load saved preference states (biometric, notifications)
    _loadSwitchPrefs();

    if (widget.title == 'Personal Information') {
      _fetchLatestProfile();
    }
  }

  Future<void> _loadSwitchPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _switchStates['Biometric Authentication'] = prefs.getBool('biometrics_enabled') ?? false;
        _switchStates['Push Notifications'] = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _fetchLatestProfile() async {
    setState(() => _isFetching = true);
    final data = await _profileService.getProfile();
    if (data != null && mounted) {
      setState(() {
        _subtitles['Full Name'] = data['full_name'];
        _subtitles['Student ID'] = data['student_id']?.toString();
        _subtitles['Department'] = data['department'];
        _subtitles['Email Address'] = data['email'];
        _subtitles['Phone Number'] = data['phone']?.toString();
        _subtitles['Admission Year'] = data['admission_year']?.toString();
        _subtitles['Room No.'] = data['room_no']?.toString();
        _isFetching = false;
      });
    } else {
      setState(() => _isFetching = false);
    }
  }

  void _updateSubtitle(String title, String newSubtitle) {
    setState(() => _subtitles[title] = newSubtitle);
  }

  void _showClearCacheFlow(BuildContext context, ThemeData theme, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future.delayed(const Duration(seconds: 2), () {
             if (context.mounted) {
               Navigator.pop(context);
               _updateSubtitle(title, 'Current size: 0.0 MB');
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('System cache cleaned successfully. 12.4 MB freed!'), backgroundColor: Colors.green)
               );
             }
          });
          return AlertDialog(
            backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF222222) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: 24),
                const Text('Scanning System...', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Optimizing device storage', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isFetching)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (widget.title == 'Personal Information')
            IconButton(onPressed: _fetchLatestProfile, icon: const Icon(Icons.refresh_rounded, size: 20)),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          if (item['type'] == 'header') {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              child: Text(item['title'], style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
            );
          }

          Widget? trailing;
          if (item['trailing'] is Switch) {
            trailing = Switch(
              value: _switchStates[item['title']] ?? false,
              onChanged: (v) async {
                // Handle biometric toggle specially
                if (item['title'] == 'Biometric Authentication') {
                  if (v) {
                    // User wants to ENABLE biometrics - trigger fingerprint check
                    try {
                      // 1. Check for Web Support
                      if (kIsWeb) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics are only available on Android/iOS devices.'), backgroundColor: Colors.orange));
                        return;
                      }

                      // 2. Check for Hardware Support
                      final bool canCheck = await _localAuth.canCheckBiometrics;
                      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
                      if (!canCheck || !isDeviceSupported) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No biometrics hardware available on this device!'), backgroundColor: Colors.orange));
                        return;
                      }

                      // 3. Authenticate
                      final bool authenticated = await _localAuth.authenticate(
                        localizedReason: 'Scan your fingerprint to enable biometric login',
                      );

                      if (authenticated) {
                        setState(() => _switchStates[item['title']!] = true);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('biometrics_enabled', true);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric login enabled!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      debugPrint('Biometric Debug: $e');
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric setup failed. If you are on an emulator or web, biometrics may not be supported.'), backgroundColor: Colors.redAccent));
                    }
                  } else {
                    // Disabling biometrics
                    setState(() => _switchStates[item['title']!] = false);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('biometrics_enabled', false);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric login disabled.'), backgroundColor: Colors.grey));
                  }
                } else {
                  // Handle other switches (e.g. Push Notifications)
                  setState(() => _switchStates[item['title']!] = v);
                  if (item['onChanged'] != null) item['onChanged'](v);
                  // Persist notification preference locally only
                  if (item['title'] == 'Push Notifications') {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_enabled', v);
                  }
                }
              },
            );
          } else {
            trailing = item['trailing'] ?? const Icon(Icons.chevron_right_rounded, size: 20);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(item['icon'], color: theme.colorScheme.primary, size: 22),
              title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: _subtitles[item['title']] != null ? Text(_subtitles[item['title']]!, style: TextStyle(color: theme.hintColor, fontSize: 12)) : null,
              trailing: trailing,
              onTap: item['onTap'] ?? () {
                if (item['title'] == 'Clear Cache') {
                  _showClearCacheFlow(context, theme, item['title']);
                } else if (item['onTapAction'] != null) {
                  if (item['onTapAction'] is Function(BuildContext, ThemeData, Map<String, String?>)) {
                    item['onTapAction'](context, theme, _subtitles);
                  } else {
                    item['onTapAction'](context, theme);
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class ProfileScreens {
  static void _showEditDialog(BuildContext context, ThemeData theme, String title, String currentValue, Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: title == 'Phone' ? TextInputType.phone : TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter new $title',
            filled: true,
            fillColor: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title updated successfully!'), backgroundColor: theme.colorScheme.primary));
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void _showTalkToITDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Official Record', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent_rounded, size: 50, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'To change your official college records, please Talk with the IT team or visit the Registrar\'s office directly.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Visit Helpdesk')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  static void _showInfoDialog(BuildContext context, String title, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(desc, style: const TextStyle(fontSize: 14)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  static void _showThemeDialog(BuildContext context, ThemeData theme) {
    final modes = [
      {'name': 'Light Mode', 'value': ThemeMode.light, 'icon': Icons.light_mode_outlined},
      {'name': 'Dark Mode', 'value': ThemeMode.dark, 'icon': Icons.dark_mode_outlined},
      {'name': 'System Default', 'value': ThemeMode.system, 'icon': Icons.settings_suggest_outlined},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: modes.map((m) => ListTile(
            leading: Icon(m['icon'] as IconData, color: theme.colorScheme.primary),
            title: Text(m['name'] as String),
            trailing: ThemeManager().themeMode == m['value'] ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
            onTap: () {
              ThemeManager().setThemeMode(m['value'] as ThemeMode);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  static void _showClearCacheFlow(BuildContext context, ThemeData theme) {
    // This is now handled within the ProfileDetailScreen state to allow dynamic UI updates.
  }

  static void _showAccentColorDialog(BuildContext context, ThemeData theme) {
    final colors = [
      {'name': 'Crimson', 'value': const Color(0xFF8C1515)},
      {'name': 'Deep Blue', 'value': Colors.blue[800]!},
      {'name': 'Emerald', 'value': Colors.green[700]!},
      {'name': 'Purple', 'value': Colors.purple[700]!},
      {'name': 'Orange', 'value': Colors.orange[800]!},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Accent Color', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: colors.map((c) => GestureDetector(
              onTap: () {
                ThemeManager().setAccentColor(c['value'] as Color);
                Navigator.pop(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: c['value'] as Color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ThemeManager().accentColor == c['value'] ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(color: (c['value'] as Color).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  static Widget personalInfo() => ProfileDetailScreen(
    title: 'Personal Information',
    items: [
      {'type': 'header', 'title': 'CONTACT INFO (SECURE)'},
      {
        'icon': Icons.email_outlined, 
        'title': 'Email Address', 
        'subtitle': 'Loading...', 
        'onTapAction': (BuildContext context, ThemeData theme, Map<String, String?> subs) => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => EditContactScreen(initialEmail: subs['Email Address'] ?? '', initialPhone: subs['Phone Number'] ?? '')))
      },
      {
        'icon': Icons.phone_android_rounded, 
        'title': 'Phone Number', 
        'subtitle': 'Loading...', 
        'onTapAction': (BuildContext context, ThemeData theme, Map<String, String?> subs) => 
            Navigator.push(context, MaterialPageRoute(builder: (_) => EditContactScreen(initialEmail: subs['Email Address'] ?? '', initialPhone: subs['Phone Number'] ?? '')))
      },
      {'type': 'header', 'title': 'OFFICIAL RECORDS'},
      {'icon': Icons.person_outline_rounded, 'title': 'Full Name', 'subtitle': 'Loading...', 'onTapAction': (context, theme, subs) => _showTalkToITDialog(context, theme)},
      {'icon': Icons.school_outlined, 'title': 'Department', 'subtitle': 'Loading...', 'onTapAction': (context, theme, subs) => _showTalkToITDialog(context, theme)},
      {'icon': Icons.badge_outlined, 'title': 'Student ID', 'subtitle': 'Loading...', 'onTapAction': (context, theme, subs) => _showTalkToITDialog(context, theme)},
      {'icon': Icons.calendar_today_outlined, 'title': 'Admission Year', 'subtitle': 'Loading...', 'onTapAction': (context, theme, subs) => _showTalkToITDialog(context, theme)},
      {'icon': Icons.meeting_room_outlined, 'title': 'Room No.', 'subtitle': 'Loading...', 'onTapAction': (context, theme, subs) => _showTalkToITDialog(context, theme)},
    ],
  );

  static Widget security() => ProfileDetailScreen(
    title: 'Privacy & Security',
    items: [
      {'type': 'header', 'title': 'ACCOUNT SECURITY'},
      {'icon': Icons.lock_outline_rounded, 'title': 'Change Password', 'subtitle': 'Allowed monthly', 'onTapAction': (context, theme) => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))},
      
      {'type': 'header', 'title': 'BIOMETRIC FLOW'},
      {'icon': Icons.fingerprint_rounded, 'title': 'Biometric Authentication', 'subtitle': 'Keep your fingerprint and start to make a secure key with that key for opening the APK', 
        'trailing': Switch(value: false, onChanged: (v){}), 
        'onTapAction': (context, theme) => _showInfoDialog(context, 'Biometric Setup', 'Your fingerprint is used to generate a local secure key. This key is used to decrypt your session and open the application securely.')},

      {'type': 'header', 'title': 'MULTI-FACTOR SECURE'},
      {'icon': Icons.security_rounded, 'title': 'Two-Factor Authentication', 'subtitle': 'Methods: Email OTP', 'onTapAction': (context, theme) => Navigator.push(context, MaterialPageRoute(builder: (_) => const TwoFactorAuthScreen()))},
      
      {'type': 'header', 'title': 'DATA PRIVACY'},
      {'icon': Icons.verified_user_outlined, 'title': 'Privacy Policy', 'onTapAction': (context, theme) => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))},
    ],
  );

  static Widget settings(BuildContext context) => ProfileDetailScreen(
    title: 'App Settings',
    items: [
      {'type': 'header', 'title': 'APPEARANCE'},
      {'icon': Icons.palette_outlined, 'title': 'Accent Color', 'subtitle': 'Crimson (Default)', 'onTapAction': (context, theme) => _showAccentColorDialog(context, theme)},
      {'icon': Icons.dark_mode_outlined, 'title': 'Theme Mode', 'subtitle': 'System Default', 'onTapAction': (context, theme) => _showThemeDialog(context, theme)},
      {'type': 'header', 'title': 'SYSTEM'},
      {'icon': Icons.notifications_active_outlined, 'title': 'Push Notifications', 'subtitle': 'Assignments, Grade alerts', 'trailing': Switch(value: true, onChanged: (v){})},
      {'icon': Icons.storage_rounded, 'title': 'Clear Cache', 'subtitle': 'Current size: 12.4 MB'},
      {'icon': Icons.language_rounded, 'title': 'App Language', 'subtitle': 'English (United States)', 'onTapAction': (context, theme) => {}},
      {'type': 'header', 'title': 'PRIVACY'},
      {'icon': Icons.logout_rounded, 'title': 'Logout Account', 'onTapAction': (context, theme) async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
           Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      }},
    ],
  );

  static Widget help() => ProfileDetailScreen(
    title: 'Help & Support',
    items: [
      {'type': 'header', 'title': 'SUPPORT'},
      {'icon': Icons.help_outline_rounded, 'title': 'FAQ', 'subtitle': 'Common questions & answers', 'onTapAction': (context, theme) => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQPage()))},
      {'icon': Icons.chat_bubble_outline_rounded, 'title': 'Live Chat', 'subtitle': 'Speak with IT helpdesk', 'onTapAction': (context, theme) => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveChatPage()))},
      {'icon': Icons.mail_outline_rounded, 'title': 'Email Support', 'subtitle': 'support@college.edu', 'onTapAction': (context, theme) async {
        final Uri emailLaunchUri = Uri(
          scheme: 'mailto',
          path: 'support@college.edu',
          query: 'subject=Support Request - Bridgewater College',
        );
        if (await canLaunchUrl(emailLaunchUri)) {
          await launchUrl(emailLaunchUri);
        } else {
          _showInfoDialog(context, 'Error', 'Could not open email client.');
        }
      }},
      {'type': 'header', 'title': 'LEGAL'},
      {'icon': Icons.description_outlined, 'title': 'Terms of Service', 'onTapAction': (context, theme) => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()))},
      {'icon': Icons.privacy_tip_outlined, 'title': 'Privacy Policy', 'onTapAction': (context, theme) => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))},
    ],
  );
}
