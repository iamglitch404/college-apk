import 'package:flutter/material.dart';
import '../services/academic_service.dart';

class LeaveNoteScreen extends StatefulWidget {
  const LeaveNoteScreen({super.key});

  @override
  State<LeaveNoteScreen> createState() => _LeaveNoteScreenState();
}

class _LeaveNoteScreenState extends State<LeaveNoteScreen> {
  final _academicService = AcademicService();
  List<Map<String, dynamic>> _leaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() => _isLoading = true);
    final data = await _academicService.getLeaveNotes();
    if (mounted) {
      setState(() {
        _leaves = data;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  void _showLeaveNoteDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();

    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickStartDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: startDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 180)),
            );
            if (picked != null) {
              setDialogState(() {
                startDate = picked;
                startDateController.text = _formatDate(picked);
                if (endDate != null && endDate!.isBefore(startDate!)) {
                  endDate = null;
                  endDateController.clear();
                }
              });
            }
          }

          Future<void> pickEndDate() async {
            if (startDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Start Date first!')));
              return;
            }
            final picked = await showDatePicker(
              context: context,
              initialDate: endDate ?? startDate!,
              firstDate: startDate!,
              lastDate: DateTime.now().add(const Duration(days: 180)),
            );
            if (picked != null) {
              setDialogState(() {
                endDate = picked;
                endDateController.text = _formatDate(picked);
              });
            }
          }

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            contentPadding: const EdgeInsets.all(24),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.note_add_outlined, color: Colors.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text('Apply for Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Subject
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      hintText: 'e.g. Sick Leave',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.subject_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startDateController,
                          readOnly: true,
                          onTap: pickStartDate,
                          decoration: InputDecoration(
                            labelText: 'From',
                            hintText: 'Start',
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.date_range_rounded, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endDateController,
                          readOnly: true,
                          onTap: pickEndDate,
                          decoration: InputDecoration(
                            labelText: 'To (Opt)',
                            hintText: 'End',
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            prefixIcon: const Icon(Icons.event_busy_rounded, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Reason Description',
                      hintText: 'Detailed explanation...',
                      filled: true,
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (subjectController.text.trim().isEmpty || 
                            descController.text.trim().isEmpty || 
                            startDateController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields!')));
                          return;
                        }
                        
                        final subjectText = subjectController.text.trim();
                        final descText = descController.text.trim();
                        final startText = startDateController.text.trim();
                        final endText = endDateController.text.trim();
                        
                        Navigator.pop(context);
                        
                        // Optimistically update the UI to show immediately at the top
                        final newLeave = {
                          'subject': subjectText,
                          'description': descText,
                          'start_date': startText,
                          'end_date': endText,
                          'status': 'Pending',
                          'created_at': DateTime.now().toIso8601String(),
                        };

                        setState(() {
                          _leaves.insert(0, newLeave);
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submitting application...'), backgroundColor: Colors.blueAccent)
                        );
                        
                        // Save to database behind the scenes
                        final success = await _academicService.submitLeaveNote(subjectText, descText, startText, endText);
                        
                        if (!success && mounted) {
                          // Network Error Rollback
                          setState(() {
                             _leaves.remove(newLeave);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to submit. Please check your connection.'), backgroundColor: Colors.redAccent)
                          );
                        } else if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Leave application successfully submitted!'), backgroundColor: Colors.green)
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('SUBMIT APPLICATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            ),
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
        title: const Text('Leave Applications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showLeaveNoteDialog,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadLeaves,
            child: _leaves.isEmpty 
              ? ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: Text("You haven't requested any leaves yet.", style: TextStyle(color: Colors.grey, fontSize: 15)),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _leaves.length,
                  itemBuilder: (context, index) {
                    final leave = _leaves[index];
                    final status = leave['status']?.toString() ?? 'Pending';
                    final subject = leave['subject']?.toString() ?? 'Leave Note';
                    final reason = leave['description']?.toString() ?? leave['reason']?.toString() ?? '';
                    final adminReply = leave['admin_reply']?.toString() ?? '';
                    final startDate = leave['start_date']?.toString() ?? '';
                    final endDate = leave['end_date']?.toString() ?? '';
                    
                    final dateDisplay = (endDate.trim().isNotEmpty) ? '$startDate  →  $endDate' : startDate;
                    
                    Color statusColor = Colors.orange;
                    IconData statusIcon = Icons.hourglass_empty_rounded;
                    
                    if (status.toLowerCase() == 'accepted' || status.toLowerCase() == 'approved') {
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle_rounded;
                    } else if (status.toLowerCase() == 'rejected') {
                      statusColor = Colors.redAccent;
                      statusIcon = Icons.cancel_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.1),
                            child: Icon(statusIcon, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month_rounded, size: 14, color: theme.hintColor),
                                    const SizedBox(width: 6),
                                    Text(dateDisplay, style: TextStyle(color: theme.hintColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(reason, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.4)),
                                if (adminReply.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.black26 : Colors.grey[100],
                                      border: Border(left: BorderSide(color: statusColor, width: 3)),
                                      borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Admin Reply:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                                        const SizedBox(height: 4),
                                        Text(adminReply, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black87, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
    );
  }
}
