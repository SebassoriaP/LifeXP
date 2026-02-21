// lib/dashboard/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import 'models.dart';

final dashboardHeatmapProvider =
    FutureProvider.autoDispose<List<HeatmapDay>>((ref) async {
  final SupabaseClient sb = ref.read(supabaseProvider);
  final res = await sb.rpc('dashboard_heatmap_90d');
  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map(HeatmapDay.fromJson).toList();
});

final dashboardWeeklyFocusProvider =
    FutureProvider.autoDispose<List<WeeklyFocusRow>>((ref) async {
  final SupabaseClient sb = ref.read(supabaseProvider);
  final res = await sb.rpc('dashboard_focus_weekly', params: {'p_weeks': 8});
  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map(WeeklyFocusRow.fromJson).toList();
});

final dashboardTopHabitsProvider =
    FutureProvider.autoDispose<List<TopHabitRow>>((ref) async {
  final SupabaseClient sb = ref.read(supabaseProvider);
  final res = await sb.rpc('dashboard_top_habits', params: {
    'p_limit': 5,
    'p_days': 30,
  });
  final list = (res as List).cast<Map<String, dynamic>>();
  return list.map(TopHabitRow.fromJson).toList();
});