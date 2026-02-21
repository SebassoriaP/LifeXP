import 'package:supabase_flutter/supabase_flutter.dart';

class PlayerRepo {
  PlayerRepo(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> getStats() async {
    final res = await _client.rpc('player_stats');
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> getMetrics() async {
    final res = await _client.rpc('player_metrics');
    return Map<String, dynamic>.from(res as Map);
  }
}
