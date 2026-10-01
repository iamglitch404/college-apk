import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_screen.dart';
import 'assignments_screen.dart';
import 'notices_screen.dart';
import 'profile_details_screen.dart';
import 'leave_note_screen.dart';
import '../services/academic_service.dart';
import '../services/profile_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _academicService = AcademicService();
  final _profileService = ProfileService();
  
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _hasNotifications = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _attendance;
  List<Map<String, dynamic>> _timetable = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _results = [];
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchAllData();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
    });
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getProfile();
      final results = await Future.wait([
        Future.value(profile),
        _academicService.getAttendance(),
        _academicService.getTimetable(
          department: profile?['department'],
          year: (profile?['admission_year'] as num?)?.toInt(),
          roomNo: profile?['room_no'],
        ),
        _academicService.getNotices(
          department: profile?['department'],
          roomNo: profile?['room_no']?.toString(),
        ),
        _academicService.getResults(),
        _academicService.getAssignments(
          department: profile?['department'],
          year: (profile?['admission_year'] as num?)?.toInt(),
          roomNo: profile?['room_no'],
        ),
        _academicService.getNotifications(
          studentId: profile?['student_id']?.toString(),
          department: profile?['department'],
          roomNo: profile?['room_no']?.toString(),
        ),
      ]);

      if (mounted) {
        final attendanceList = results[1] as List<Map<String, dynamic>>;
        int totalPresent = 0;
        int totalDays = 0;
        for (var item in attendanceList) {
          totalPresent += (item['present_days'] as num? ?? 0).toInt();
          totalDays += (item['total_days'] as num? ?? 0).toInt();
        }
        
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _attendance = {
            'total_classes': totalDays,
            'present_classes': totalPresent,
          };
          _timetable = results[2] as List<Map<String, dynamic>>;
          _notices = results[3] as List<Map<String, dynamic>>;
          _results = results[4] as List<Map<String, dynamic>>;
          _assignments = results[5] as List<Map<String, dynamic>>;
          _notifications = results[6] as List<Map<String, dynamic>>;
          _hasNotifications = _notifications.isNotEmpty;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard Data Load Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchAllData();
  }

  String _getGreeting() {
    final nowNepal = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 45));
    final hour = nowNepal.hour;
    if (hour >= 5 && hour < 12) return 'Good Morning ☀️';
    if (hour >= 12 && hour < 17) return 'Good Afternoon 🌤️';
    if (hour >= 17 && hour < 21) return 'Good Evening 🌇';
    return 'Good Night 🌙';
  }

  String _getNepalTime() {
    final nowNepal = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 45));
    final minute = nowNepal.minute.toString().padLeft(2, '0');
    final hour = nowNepal.hour > 12 ? nowNepal.hour - 12 : (nowNepal.hour == 0 ? 12 : nowNepal.hour);
    final amPm = nowNepal.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm (Nepal Time)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      endDrawer: _buildNotificationDrawer(theme),
      bottomNavigationBar: _buildBottomNavBar(theme),
      body: _isLoading
          ? _buildLoadingState(theme)
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(theme),
                const AttendanceScreen(),
                AssignmentsScreen(assignments: _assignments, studentId: _profile?['student_id'] ?? ''),
                _buildProfileTab(),
              ],
            ),
    );
  }

  Widget _buildHomeTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: 60,
      color: theme.colorScheme.primary,
      child: CustomScrollView(
        slivers: [
          _buildHeader(theme),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSearchBar(theme),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, 'Quick Actions'),
                const SizedBox(height: 16),
                _buildQuickActions(theme),
                const SizedBox(height: 24),
                _buildAttendanceBoard(theme),
                const SizedBox(height: 32),
                
                _buildSectionTitle(theme, "Today's Timetable", actionText: 'View All', route: '/timetable'),
                const SizedBox(height: 16),
                _buildTimetableList(theme),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, "Active Assignments", actionText: '${_assignments.length} Total', route: '/assignments'),
                const SizedBox(height: 16),
                _buildAssignmentsList(theme),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, "Recent Results", actionText: 'Details', route: '/results'),
                const SizedBox(height: 16),
                _buildResultsGrid(theme),
                const SizedBox(height: 24),
                _buildSectionTitle(theme, "Latest Notices", actionText: 'Archive', route: '/notices'),
                const SizedBox(height: 16),
                _buildNoticesList(theme),
                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildLoadingState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 210,
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary.withValues(alpha: 0.1),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(color: baseColor)
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _skeletonBox(100, 20, baseColor),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _skeletonBox(double.infinity, 80, baseColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _skeletonBox(double.infinity, 80, baseColor)),
                  const SizedBox(width: 12),
                  Expanded(child: _skeletonBox(double.infinity, 80, baseColor)),
                ],
              ),
              const SizedBox(height: 24),
              _skeletonBox(double.infinity, 120, baseColor),
              const SizedBox(height: 24),
              _skeletonBox(150, 20, baseColor),
              const SizedBox(height: 16),
              _skeletonBox(double.infinity, 70, baseColor),
              const SizedBox(height: 12),
              _skeletonBox(double.infinity, 70, baseColor),
              const SizedBox(height: 24),
              _skeletonBox(double.infinity, 150, baseColor),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _skeletonBox(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.05));
  }

  Widget _buildHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 210,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : theme.colorScheme.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 1.0,
        child: const Text('Bridgewater College', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 26),
            ),
            if (_hasNotifications)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ).animate(onPlay: (c) => c.repeat()).fade(duration: 1000.ms, begin: 0.3, end: 1.0),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [const Color(0xFF2C2C2C), const Color(0xFF1A1A1A)] 
                : [theme.colorScheme.primary, theme.colorScheme.primary.withRed(150)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative Glass Circles
              Positioned(
                right: -30,
                bottom: -30,
                child: CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Positioned(
                left: -20,
                top: -20,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white.withValues(alpha: 0.03),
                ),
              ),
              // Main Header Content
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 60),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getGreeting(),
                            style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _profile?['full_name'] ?? 'Student',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.school_rounded, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  '${_profile?['department'] ?? 'Department'} • ID: ${_profile?['student_id'] ?? 'N/A'}',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    // Large Avatar with Glass Effect
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: GestureDetector(
                      onTap: () => setState(() => _currentIndex = 3),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white24,
                        backgroundImage: (_profile?['avatar_url'] != null && (_profile!['avatar_url'] as String).isNotEmpty)
                            ? NetworkImage(_profile!['avatar_url'] as String)
                            : null,
                        child: (_profile?['avatar_url'] == null || (_profile!['avatar_url'] as String).isEmpty)
                            ? Text(
                                (_profile?['full_name'] ?? 'S').substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, {String? actionText, String? route}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        if (actionText != null)
          TextButton(
            onPressed: () {
              if (route == '/attendance') {
                setState(() => _currentIndex = 1);
              } else if (route == '/assignments') {
                setState(() => _currentIndex = 2);
              } else if (route == '/notices') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => NoticesScreen(notices: _notices)));
              } else if (route != null) {
                Navigator.pushNamed(context, route);
              }
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
            child: Text(
              actionText,
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    final actions = [
      {'icon': Icons.assignment_turned_in_rounded, 'label': 'Attendance', 'color': Colors.green, 'route': '/attendance'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Timetable', 'color': Colors.blue, 'route': '/timetable'},
      {'icon': Icons.payment_rounded, 'label': 'Fees', 'color': Colors.teal, 'route': '/fees'},
      {'icon': Icons.grade_rounded, 'label': 'Results', 'color': Colors.amber, 'route': '/results'},
      {'icon': Icons.library_books_rounded, 'label': 'Notices', 'color': Colors.purple, 'route': '/notices'},
      {'icon': Icons.quiz_rounded, 'label': 'Exam', 'color': Colors.orange, 'route': '/exam'},
      {'icon': Icons.note_alt_rounded, 'label': 'Leave Note', 'color': Colors.blueAccent, 'action': (BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveNoteScreen()))},
      {'icon': Icons.map_rounded, 'label': 'Campus Map', 'color': Colors.redAccent, 'route': '/map'},
      {'icon': Icons.help_outline_rounded, 'label': 'Support', 'color': Colors.indigo, 'action': (BuildContext context) => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreens.help()))},
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return InkWell(
          onTap: () {
            if (action.containsKey('route')) {
              final route = action['route'] as String;
              if (route == '/attendance') {
                setState(() => _currentIndex = 1);
              } else if (route == '/assignments') {
                setState(() => _currentIndex = 2);
              } else if (route == '/notices') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => NoticesScreen(notices: _notices)));
              } else {
                Navigator.pushNamed(context, route);
              }
            } else if (action.containsKey('action')) {
              final actionFunc = action['action'] as Function(BuildContext);
              actionFunc(context);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: theme.brightness == Brightness.light
                  ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action['icon'] as IconData, color: action['color'] as Color, size: 28),
                const SizedBox(height: 8),
                Text(
                  action['label'] as String,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceBoard(ThemeData theme) {
    if (_attendance == null || _attendance!['total_classes'] == 0) {
       return _buildEmptyState('No attendance records yet');
    }

    final total = _attendance!['total_classes'] as int;
    final present = _attendance!['present_classes'] as int;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;
    final isLow = percentage < 75;

    return InkWell(
      onTap: () => setState(() => _currentIndex = 1),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.brightness == Brightness.dark
                ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
                : [Colors.white, Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 8,
                    backgroundColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
                    color: isLow ? Colors.redAccent : Colors.blueAccent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toInt()}%',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('Total', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Attendance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isLow ? 'Warning: Low attendance' : 'Great progress! Keep it up.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isLow ? Colors.redAccent : Colors.grey,
                      fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                   Row(
                    children: [
                      _buildMiniStat('Present', '$present', Colors.green),
                      const SizedBox(width: 16),
                      _buildMiniStat('Absent', '${total - present}', Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMock(ThemeData theme) {
    return _buildEmptyState('No attendance records yet');
  }

  Widget _buildAttendanceUI(ThemeData theme, double percentage, int present, int absent, {bool isMock = false}) {
    final isLow = percentage < 75;
    return InkWell(
      onTap: () => setState(() => _currentIndex = 1),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            CircularProgressIndicator(value: percentage / 100, color: isLow ? Colors.redAccent : Colors.blueAccent),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isMock ? 'Mock Attendance' : 'Your Attendance', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${percentage.toInt()}% Performance', style: TextStyle(color: isLow ? Colors.redAccent : Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }



  Widget _buildAssignmentsList(ThemeData theme) {
    if (_assignments.isEmpty) {
      return _buildEmptyState('There\'s no assignment for u');
    }

    // Sort or just pick top 3 for dashboard
    final latestAssignments = _assignments.take(3).toList();

    return Column(
      children: latestAssignments.map((a) {
        final dueDate = DateTime.parse(a['due_date'].toString());
        final formatter = dueDate.day == DateTime.now().day && dueDate.month == DateTime.now().month && dueDate.year == DateTime.now().year ? 'Today' : '${dueDate.day}/${dueDate.month}';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _currentIndex = 2),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      a['subject']?.toString().substring(0, a['subject'].toString().length > 2 ? 3 : a['subject'].toString().length).toUpperCase() ?? 'HW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          'Due: $formatter',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResultsGrid(ThemeData theme) {
    // If no results are available
    if (_results.isEmpty) {
      return _buildEmptyState('No results published yet');
    }

    final latestGpaNum = _results.firstWhere((r) => r['gpa'] != null, orElse: () => {'gpa': null})['gpa'];
    final gpa = latestGpaNum != null ? (latestGpaNum as num).toStringAsFixed(2) : 'N/A';

    final latestResults = _results.take(3).toList();

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/results'),
      borderRadius: BorderRadius.circular(20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Latest GPA', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text(gpa, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Icon(Icons.trending_up_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: latestResults.map((r) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(r['subject_name']?.toString() ?? r['subject']?.toString() ?? r['exam_title']?.toString() ?? 'Sub', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(r['grade']?.toString() ?? '-', style: TextStyle(fontSize: 18, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticesList(ThemeData theme) {
    if (_notices.isEmpty) {
      return _buildEmptyState('No new notices');
    }

    final recentNotices = _notices.take(3).toList();

    return Column(
      children: recentNotices.map((n) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_outlined, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(n['title']?.toString() ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(n['content']?.toString() ?? n['desc']?.toString() ?? '', style: TextStyle(color: theme.hintColor, fontSize: 12, height: 1.4)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.grey, size: 40),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))
        ],
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.assignment_ind_outlined), selectedIcon: Icon(Icons.assignment_ind_rounded), label: 'Attendance'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment_rounded), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: theme.colorScheme.primary,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white24,
                      backgroundImage: (_profile?['avatar_url'] != null && (_profile!['avatar_url'] as String).isNotEmpty)
                          ? NetworkImage(_profile!['avatar_url'] as String)
                          : null,
                      child: (_profile?['avatar_url'] == null || (_profile!['avatar_url'] as String).isEmpty)
                          ? Text(
                              (_profile?['full_name'] ?? 'S').substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(_profile?['full_name'] ?? 'User Profile', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('${_profile?['department'] ?? 'BWIC Student'} • Year ${_profile?['admission_year'] ?? '1'}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   _buildProfileItem(Icons.person_outline, 'Personal Information', '${_profile?['full_name'] ?? 'Loading...'}, ${_profile?['email'] ?? 'Loading...'}', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreens.personalInfo()))),
                   _buildProfileItem(Icons.security_outlined, 'Privacy & Security', 'Change password, Two-factor auth', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreens.security()))),
                   _buildProfileItem(Icons.settings_outlined, 'App Settings', 'Theme, Notifications, Language', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreens.settings(context)))),
                   _buildProfileItem(Icons.help_outline_rounded, 'Help & Support', 'FAQ, Contact Support', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreens.help()))),
                   const SizedBox(height: 20),
                   ListTile(
                     leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                     title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                     onTap: () => Navigator.pushReplacementNamed(context, '/'),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: theme.hintColor, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search courses, results...',
          hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildNotificationDrawer(ThemeData theme) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(left: Radius.circular(24))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (_hasNotifications)
                   TextButton(
                    onPressed: () {
                      setState(() => _hasNotifications = false);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                else
                  const Icon(Icons.done_all_rounded, color: Colors.green, size: 20),
              ],
            ),
          ),
          Expanded(
            child: _notifications.isEmpty
              ? const Center(child: Text('No unread notifications.', style: TextStyle(color: Colors.grey, fontSize: 13)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: _notifications.map((n) {
                    final title = n['title']?.toString() ?? 'Notification';
                    final content = n['content']?.toString() ?? n['desc']?.toString() ?? '';
                    
                    String timeStr = 'Just now';
                    if (n['created_at'] != null) {
                      final date = DateTime.parse(n['created_at'].toString());
                      final diff = DateTime.now().difference(date);
                      if (diff.inDays > 0) {
                        timeStr = '${diff.inDays}d ago';
                      } else if (diff.inHours > 0) timeStr = '${diff.inHours}h ago';
                      else if (diff.inMinutes > 0) timeStr = '${diff.inMinutes}m ago';
                    }

                    return _buildNotificationItem(
                      theme, 
                      Icons.notifications_active_outlined, 
                      title, 
                      content, 
                      timeStr, 
                      theme.colorScheme.primary
                    );
                  }).toList(),
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
               width: double.infinity,
               child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close Drawer')),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context, ThemeData theme) {
    // Hidden, now handled by endDrawer
  }

  Widget _buildNotificationItem(ThemeData theme, IconData icon, String title, String desc, String time, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      onTap: () => _showNotificationDetail(theme, title, desc, icon, color),
    );
  }

  void _showNotificationDetail(ThemeData theme, String title, String desc, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 30, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 30)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(desc, textAlign: TextAlign.center, style: TextStyle(color: theme.hintColor, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetableList(ThemeData theme) {
    if (_timetable.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, color: theme.hintColor, size: 32),
            const SizedBox(height: 12),
            const Text(
              'Seems to be a holiday!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enjoy your free time.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _timetable.length > 3 ? 3 : _timetable.length, // Show top 3 on home
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = _timetable[index];
        return InkWell(
          onTap: () => Navigator.pushNamed(context, '/timetable'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (c['time_start'] ?? '00:00').toString().split(' ')[0],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c['subject_name'] ?? 'Class', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${c['teacher_name'] ?? 'Faculty'} • ${c['room_number'] ?? 'Auditorium'}', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
