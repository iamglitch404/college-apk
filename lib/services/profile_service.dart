import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('student_id');
    if (studentId == null) return null;

    final cacheKey = 'cache_profile_$studentId';

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('student_id', studentId)
          .maybeSingle();
      
      if (data != null) {
        await prefs.setString(cacheKey, jsonEncode(data));
      }
      return data;
    } catch (e) {
      debugPrint('Error fetching profile (Offline fallback): $e');
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        return jsonDecode(cachedStr) as Map<String, dynamic>;
      }
      return null;
    }
  }

  // Helper to sync profile manually
  Future<void> syncProfile() async => await getProfile();

  Future<void> updateProfile({
    required String fullName,
    String? department,
    String? studentId,
    int? admissionYear,
    String? email,
    String? roomNo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentId = studentId ?? prefs.getString('student_id');
    if (currentId == null) return;

    try {
      await _supabase.from('profiles').update({
        'full_name': fullName,
        'department': department,
        'student_id': studentId,
        'email': email,
        'admission_year': admissionYear,
        'room_no': roomNo,
      }).eq('student_id', currentId);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }
}
