import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerRepo {
  PlayerRepo(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getTodayPlan() async {
    final res = await _client.rpc('today_plan');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> getHabitStreaks({int days = 90}) async {
    final res = await _client.rpc('habit_streaks', params: {'p_days': days});
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _client.rpc('player_stats');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getMetrics() async {
    final res = await _client.rpc('player_metrics');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getFocusQualityWeek() async {
    final res = await _client.rpc('player_focus_quality_week');
    return Map<String, dynamic>.from(res as Map);
  }
}
