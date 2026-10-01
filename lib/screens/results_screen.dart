import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/academic_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _academicService = AcademicService();
  List<Map<String, dynamic>> _resultsData = [];
  bool _isLoading = true;
  int? _latestRank;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('student_id') ?? '';
    final data = await _academicService.getResults();

    int? rank;
    if (data.isNotEmpty && data.first['exam_id'] != null) {
      rank = await _academicService.getExamRank(data.first['exam_id'].toString(), studentId);
    }

    if (mounted) {
      setState(() {
        _resultsData = data;
        _latestRank = rank;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group by Exam Title
    Map<String, List<Map<String, dynamic>>> groupedResults = {};
    for (var res in _resultsData) {
      final examTitle = res['exam_title']?.toString() ?? 'General Exam';
      groupedResults.putIfAbsent(examTitle, () => []).add(res);
    }

    double latestGPA = 0.0;
    if (_resultsData.isNotEmpty) {
      latestGPA = (_resultsData.first['gpa'] as num?)?.toDouble() ?? 0.0;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Academic Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadResults,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGPAHeader(theme, latestGPA, _latestRank),
                  const SizedBox(height: 24),
                  const Text('Semester-wise Results', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_resultsData.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('No results records available.', style: TextStyle(color: Colors.grey)),
                    )),
                  ...groupedResults.entries.map((entry) {
                    double semGPA = 0;
                    for (var r in entry.value) { semGPA += (r['gpa'] as num? ?? 0).toDouble(); }
                    semGPA = entry.value.isEmpty ? 0 : semGPA / entry.value.length;
                    
                    return _buildSemesterCard(
                      theme, 
                      entry.key, 
                      semGPA.toStringAsFixed(2), 
                      entry.value
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildGPAHeader(ThemeData theme, double gpa, int? rank) {
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
          const Text('Latest Exam GPA', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(gpa.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(rank != null ? Icons.emoji_events_rounded : Icons.star_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(rank != null ? 'College Rank: #$rank' : 'Academic Standing: Good', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterCard(ThemeData theme, String title, String gpa, List<Map<String, dynamic>> results) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('GPA: $gpa', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        children: results.map((r) {
          final subject = r['subject_name']?.toString() ?? r['subject']?.toString() ?? 'Overall Grade';
          final grade = '${r['grade'] ?? 'N/A'} ${r['status'] != null ? '(${r['status']})' : ''}'.trim();
          final url = r['url']?.toString();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(subject, style: TextStyle(color: theme.hintColor))),
                    Text(grade, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                if (url != null && url.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.all(10),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                InteractiveViewer(
                                  child: Image.network(url, fit: BoxFit.contain, 
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 50)
                                  )
                                ),
                                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white))
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 60,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                            child: const Text('View Document', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
