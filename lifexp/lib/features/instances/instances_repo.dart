import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class InstancesRepo {
  InstancesRepo(this._client);
  final SupabaseClient _client;

  Future<void> ensureTodayInstances() async {
    await _client.rpc('ensure_today_instances');
  }

  Future<bool> hasCompletedToday() async {
    final res = await _client.rpc('has_completed_today');
    final value = (res as bool?) ?? false;
    debugPrint('[InstancesRepo] hasCompletedToday(server_date)=$value');
    return value;
  }

  Future<bool> hasCompletedForLocalDate() async {
    final localDate = DateTime.now().toLocal().toIso8601String().substring(
      0,
      10,
    );
    try {
      final res = await _client.rpc(
        'has_completed_on',
        params: {'p_date': localDate},
      );
      final value = (res as bool?) ?? false;
      debugPrint('[InstancesRepo] hasCompletedOn(local=$localDate)=$value');
      return value;
    } catch (_) {
      // Fallback for deployments where has_completed_on is not available yet.
      return hasCompletedToday();
    }
  }

  Future<List<Map<String, dynamic>>> listTodayInstances() async {
    final todayUtc = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final res = await _client
        .from('habit_instances')
        .select(
          'id, status, date, completed_at, habit_id, habits(title, preferred_time, expected_minutes)',
        )
        .eq('date', todayUtc)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<bool> completeInstance(String instanceId, {int xp = 10}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final updated = await _client
        .from('habit_instances')
        .update({
          'status': 'completed',
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', instanceId)
        .neq('status', 'completed')
        .select('id');

    final changed = (updated as List).isNotEmpty;
    if (!changed) return false;

    await _client.from('events').insert([
      {
        'user_id': uid,
        'type': 'instance_completed',
        'payload': {'instance_id': instanceId},
      },
      {
        'user_id': uid,
        'type': 'xp_awarded',
        'payload': {
          'xp': xp,
          'reason': 'complete_instance',
          'instance_id': instanceId,
        },
      },
    ]);

    return true;
  }
}
