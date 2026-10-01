import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bridgewatercollege/config/app_config.dart';
import 'package:bridgewatercollege/screens/auth/login_screen.dart';
import 'package:bridgewatercollege/screens/auth/signup_screen.dart';
import 'package:bridgewatercollege/screens/dashboard_screen.dart';
import 'package:bridgewatercollege/screens/timetable_screen.dart';
import 'package:bridgewatercollege/screens/attendance_screen.dart';
import 'package:bridgewatercollege/screens/results_screen.dart';
import 'package:bridgewatercollege/screens/exam_screen.dart';
import 'package:bridgewatercollege/screens/fees_screen.dart';
import 'package:bridgewatercollege/screens/map_page.dart';
import 'package:bridgewatercollege/screens/security/biometric_gate_screen.dart';
import 'package:bridgewatercollege/theme/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Theme Manager
  await ThemeManager().init();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final studentId = prefs.getString('student_id');

  runApp(MyApp(initialRoute: studentId != null ? '/home' : '/'));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    _themeManager.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _themeManager.removeListener(() => setState(() {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bridgewater College',
      themeMode: _themeManager.themeMode, 
      theme: _themeManager.lightTheme,
      darkTheme: _themeManager.darkTheme,
      initialRoute: widget.initialRoute,
      routes: {
        '/': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const BiometricGateScreen(child: DashboardScreen()),
        '/timetable': (context) => const TimetableScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/results': (context) => const ResultsScreen(),
        '/exam': (context) => const ExamScreen(),
        '/fees': (context) => const FeesScreen(),
        '/map': (context) => const MapPage(),
      },
    );
  }
}
