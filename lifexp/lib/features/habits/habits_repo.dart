import 'package:supabase_flutter/supabase_flutter.dart';

class HabitsRepo {
  HabitsRepo(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listActiveHabits() async {
    final res = await _client
        .from('habits')
        .select(
          'id,title,active,created_at,schedule_type,days_of_week,preferred_time,expected_minutes,window_start,window_end',
        )
        .eq('active', true)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> listAllHabits() async {
    final res = await _client
        .from('habits')
        .select(
          'id,title,active,created_at,schedule_type,days_of_week,preferred_time,expected_minutes,window_start,window_end',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> createHabit({
    required String title,
    String scheduleType = 'weekly',
    required List<int> daysOfWeek,
    required String preferredTime,
    int expectedMinutes = 30,
    String windowStart = '13:00:00',
    String windowEnd = '22:00:00',
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    await _client.from('habits').insert({
      'user_id': uid,
      'title': title,
      'schedule_type': scheduleType,
      'days_of_week': daysOfWeek,
      'preferred_time': preferredTime,
      'expected_minutes': expectedMinutes,
      'window_start': windowStart,
      'window_end': windowEnd,
      'active': true,
    });
  }

  Future<void> setHabitActive(String habitId, bool active) async {
    await _client.from('habits').update({'active': active}).eq('id', habitId);
  }

  Future<void> updateHabit({
    required String habitId,
    required String title,
    required bool active,
    required List<int> daysOfWeek,
    required String preferredTime,
    required int expectedMinutes,
    String windowStart = '13:00:00',
    String windowEnd = '22:00:00',
  }) async {
    await _client
        .from('habits')
        .update({
          'title': title,
          'active': active,
          'schedule_type': 'weekly',
          'days_of_week': daysOfWeek,
          'preferred_time': preferredTime,
          'expected_minutes': expectedMinutes,
          'window_start': windowStart,
          'window_end': windowEnd,
        })
        .eq('id', habitId);
  }
}
