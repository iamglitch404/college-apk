import 'package:flutter/material.dart';
import '../services/academic_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _academicService = AcademicService();
  List<Map<String, dynamic>> _attendanceData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final data = await _academicService.getAttendance();
    if (mounted) {
      setState(() {
        _attendanceData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate Totals Safely
    int totalPresent = 0;
    int totalDays = 0;
    for (var item in _attendanceData) {
      totalPresent += (item['present_days'] as num? ?? 0).toInt();
      totalDays += (item['total_days'] as num? ?? 0).toInt();
    }
    double overallPercentage = totalDays == 0 ? 0.0 : (totalPresent / totalDays) * 100;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Attendance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadAttendance,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAttendanceSummary(theme, overallPercentage, totalPresent, totalDays),
                    const SizedBox(height: 24),
                    const Text('Monthly Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_attendanceData.isEmpty)
                      const Center(child: Text('No attendance records for this year.', style: TextStyle(color: Colors.grey))),
                    ..._attendanceData.map((item) => _buildAttendanceItem(
                      theme, 
                      item['month_name'] ?? 'Month', 
                      (item['present_days'] as num? ?? 0).toInt(), 
                      (item['total_days'] as num? ?? 0).toInt(), 
                      _getMonthColor(item['month_name'] ?? '')
                    )),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Color _getMonthColor(String month) {
    if (month.contains('Jan') || month.contains('Feb')) return Colors.blueAccent;
    if (month.contains('Mar') || month.contains('Apr')) return Colors.green;
    return Colors.orange;
  }

  Widget _buildAttendanceSummary(ThemeData theme, double percentage, int present, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Present', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white12,
                child: Icon(Icons.show_chart_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryStat('Lectures', '$total'),
              _buildSummaryStat('Present', '$present'),
              _buildSummaryStat('Absent', '${total - present}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAttendanceItem(ThemeData theme, String title, int present, int total, Color color) {
    final ratio = total == 0 ? 0.0 : present / total;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('$present / $total', style: TextStyle(color: theme.hintColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.grey[100],
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Text('${(ratio * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
              const Spacer(),
              const Text('Target: 75%', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
