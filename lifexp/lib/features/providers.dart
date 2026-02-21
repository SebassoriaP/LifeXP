import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase/supabase_client.dart';
import 'habits/habits_repo.dart';
import 'instances/instances_repo.dart';
import 'player/player_repo.dart';
import 'focus/focus_repo.dart';

final todayInstancesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(instancesRepoProvider);
  return repo.listTodayInstances();
});

final focusRepoProvider = Provider<FocusRepo>((ref) {
  final client = ref.watch(supabaseProvider);
  return FocusRepo(client);
});

final playerRepoProvider = Provider<PlayerRepo>((ref) {
  final client = ref.watch(supabaseProvider);
  return PlayerRepo(client);
});

final playerStatsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(playerRepoProvider);
  return repo.getStats();
});

final habitsRepoProvider = Provider<HabitsRepo>((ref) {
  final client = ref.watch(supabaseProvider);
  return HabitsRepo(client);
});

final instancesRepoProvider = Provider<InstancesRepo>((ref) {
  final client = ref.watch(supabaseProvider);
  return InstancesRepo(client);
});

final playerMetricsProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(playerRepoProvider);
  return repo.getMetrics();
});
