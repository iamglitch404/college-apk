import 'package:flutter/material.dart';
import '../services/academic_service.dart';
import '../services/profile_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _academicService = AcademicService();
  final _profileService = ProfileService();
  
  int _selectedDayIndex = 0;
  final List<String> _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  
  List<Map<String, dynamic>> _allTimetableData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getProfile();
      final data = await _academicService.getTimetable(
        department: profile?['department'],
        year: (profile?['admission_year'] as num?)?.toInt(),
        roomNo: profile?['room_no'],
      );
      if (mounted) {
        setState(() {
          _allTimetableData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Filter by selected day (1-indexed for Sunday. e.g., Sun=1, Mon=2)
    final dailyClasses = _allTimetableData.where((item) => (item['day_of_week'] as num?)?.toInt() == (_selectedDayIndex + 1)).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Academic Timetable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildDaySelector(theme),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : dailyClasses.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, color: theme.hintColor, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Seems to be a holiday! 🌴',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'Enjoy your free time. There are no classes scheduled for this day.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTimetable,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: dailyClasses.length,
                      itemBuilder: (context, index) => _buildScheduleCard(theme, dailyClasses[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(ThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedDayIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.colorScheme.primary 
                    : (theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected 
                    ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
                ),
                child: Center(
                  child: Text(
                    _days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.hintColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildScheduleCard(ThemeData theme, Map<String, dynamic> classInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(classInfo['time_start'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                height: 30,
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              Text(classInfo['time_end'] ?? '', style: TextStyle(color: theme.hintColor, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(classInfo['subject_name'] ?? 'Class', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.meeting_room_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(classInfo['room_number'] ?? 'Auditorium', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(classInfo['teacher_name'] ?? 'Faculty', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
