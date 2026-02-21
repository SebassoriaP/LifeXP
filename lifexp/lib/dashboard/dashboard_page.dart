// lib/dashboard/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'widgets/heatmap_grid.dart';
import 'widgets/top_habits_list.dart';
import 'widgets/weekly_focus_bars.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  void _handleHorizontalSwipe(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;

    if (velocity > 0) {
      context.go('/home');
      return;
    }
    context.go('/habits');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heatmap = ref.watch(dashboardHeatmapProvider);
    final weekly = ref.watch(dashboardWeeklyFocusProvider);
    final topHabits = ref.watch(dashboardTopHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) =>
            _handleHorizontalSwipe(context, details),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heatmap (90 días)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    heatmap.when(
                      data: (days) => HeatmapGrid(days: days),
                      loading: () => const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text(
                        'Error heatmap: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Más oscuro = más progreso (hábitos, foco y XP)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: weekly.when(
                  data: (rows) => WeeklyFocusBars(rows: rows),
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    'Error weekly focus: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: topHabits.when(
                  data: (rows) => TopHabitsList(rows: rows),
                  loading: () => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    'Error top habits: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
