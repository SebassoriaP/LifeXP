import 'package:supabase_flutter/supabase_flutter.dart';

class FocusRepo {
  FocusRepo(this._client);
  final SupabaseClient _client;

  Future<String> startSession({required String instanceId, required int plannedSeconds}) async {
    final res = await _client.rpc('start_focus_session', params: {
      'p_instance_id': instanceId,
      'p_planned_seconds': plannedSeconds,
    });
    return res as String;
  }

  Future<void> endSession({required String sessionId, required String result}) async {
    await _client.rpc('end_focus_session', params: {
      'p_session_id': sessionId,
      'p_result': result, // 'completed' or 'abandoned'
    });
  }
}