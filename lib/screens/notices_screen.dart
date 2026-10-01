import 'package:flutter/material.dart';

class NoticesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notices;
  const NoticesScreen({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Departmental Notices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: notices.isEmpty 
             ? [const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text('No notices available.', style: TextStyle(color: Colors.grey))))]
             : notices.map((n) {
                  final title = n['title']?.toString() ?? 'Notice';
                  final desc = n['content']?.toString() ?? n['desc']?.toString() ?? '';
                  
                  String timeStr = 'Just now';
                  if (n['created_at'] != null) {
                    final date = DateTime.parse(n['created_at'].toString());
                    final diff = DateTime.now().difference(date);
                    if (diff.inDays > 0) {
                      timeStr = '${diff.inDays}d ago';
                    } else if (diff.inHours > 0) timeStr = '${diff.inHours}h ago';
                    else if (diff.inMinutes > 0) timeStr = '${diff.inMinutes}m ago';
                  }

                  return _buildNoticeCard(theme, title, desc, timeStr, Icons.campaign_rounded, theme.colorScheme.primary);
               }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard(ThemeData theme, String title, String desc, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(desc, style: TextStyle(color: theme.hintColor, fontSize: 13, height: 1.5)),
                // Read Full Notice button removed
              ],
            ),
          ),
        ],
      ),
    );
  }
}
