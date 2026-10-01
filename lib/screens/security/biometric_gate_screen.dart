import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricGateScreen extends StatefulWidget {
  final Widget child;
  const BiometricGateScreen({super.key, required this.child});

  @override
  State<BiometricGateScreen> createState() => _BiometricGateScreenState();
}

class _BiometricGateScreenState extends State<BiometricGateScreen> with WidgetsBindingObserver {
  bool _isLocked = true;
  bool _isAuthenticating = false; // Prevents recursive loops
  bool _isInitialized = false;     // Prevents flickering at start
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometrics(isInitial: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Only lock when the app is truly BACKGROUNDED (paused)
    // Avoid 'inactive' as it triggers on system dialogs/notification shades
    if (state == AppLifecycleState.paused) {
      _lockApp();
    } else if (state == AppLifecycleState.resumed) {
      // Re-trigger auth if it was locked
      if (_isLocked) {
        _checkBiometrics();
      }
    }
  }

  Future<void> _lockApp() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometrics_enabled') ?? false;
    if (enabled) {
      setState(() => _isLocked = true);
    }
  }

  Future<void> _checkBiometrics({bool isInitial = false}) async {
    // If we are already authenticating, don't start another process
    if (_isAuthenticating) return;

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometrics_enabled') ?? false;
    
    if (!enabled) {
      setState(() {
        _isLocked = false;
        _isInitialized = true;
      });
      return;
    }

    // Mark as initializing so we can show a ghost state or just wait
    if (isInitial) {
      setState(() => _isInitialized = true);
    }

    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      
      if (!canCheck || !isSupported) {
        setState(() => _isLocked = false);
        return;
      }

      setState(() => _isAuthenticating = true);

      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Scan fingerprint to access your Bridgewater Profile',
      );

      setState(() {
        _isAuthenticating = false;
        if (authenticated) {
          _isLocked = false;
        }
      });
    } catch (e) {
      setState(() => _isAuthenticating = false);
      debugPrint('Biometric Lock Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized yet, show an empty scaffold to avoid flicker
    if (!_isInitialized && _isLocked) {
      return const Scaffold(backgroundColor: Colors.transparent);
    }

    if (!_isLocked) return widget.child;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, size: 64, color: Colors.blueAccent),
            ),
            const SizedBox(height: 32),
            const Text(
              'Profile is Locked',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Biometric authentication is required.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _checkBiometrics(),
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () async {
                 final prefs = await SharedPreferences.getInstance();
                 await prefs.clear();
                 if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              child: const Text('Log Out for Security'),
            ),
          ],
        ),
      ),
    );
  }
}
