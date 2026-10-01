import 'package:flutter/material.dart';
import '../services/academic_service.dart';
import '../services/profile_service.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  final _academicService = AcademicService();
  final _profileService = ProfileService();
  
  List<Map<String, dynamic>> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final profile = await _profileService.getProfile();
      final department = profile?['department'] as String?;
      
      final exams = await _academicService.getExams(
        department: department,
      );
      
      if (mounted) {
        setState(() {
          _exams = exams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Examination Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadExams,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upcoming Exams', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_exams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text("There's no upcoming exams.", style: TextStyle(color: Colors.grey, fontSize: 15)),
                      ),
                    )
                  else
                    ..._exams.map((exam) => _buildExamItem(
                      theme,
                      exam['title']?.toString() ?? 'Exam',
                      exam['start_date']?.toString() ?? 'TBA',
                      exam['end_date']?.toString() ?? 'TBA',
                      exam['exam_type']?.toString() ?? 'Exam',
                    )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }


  Widget _buildExamItem(ThemeData theme, String title, String startDate, String endDate, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(type, style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 14, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Text('$startDate - $endDate', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.article_outlined, size: 28, color: Colors.grey),
        ],
      ),
    );
  }
}
