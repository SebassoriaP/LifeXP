import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers.dart';
import '../focus/focus_page.dart';

// Dashboard providers (fase 5)
import '../../dashboard/providers.dart';

// Notifications (fase 6)
import '../../core/notifications/notification_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();

    // Run once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncStickyNotification();
      await _handlePendingAction();
    });
  }

  Future<void> _syncStickyNotification() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await NotificationService.instance.setStickyEnabled(false);
        await NotificationService.instance.stopSticky();
        return;
      }

      final completedToday = await ref
          .read(instancesRepoProvider)
          .hasCompletedForLocalDate();
      final todayLocalIso = DateTime.now()
          .toLocal()
          .toIso8601String()
          .substring(0, 10);
      var shouldStopSticky = completedToday;
      if (!completedToday) {
        final list = await ref.read(instancesRepoProvider).listTodayInstances();
        String? earliestPreferredRaw;
        int? earliestPreferredMins;
        for (final item in list) {
          final status = (item['status'] ?? 'pending') as String;
          if (status == 'completed') continue;
          final habit = item['habits'] as Map<String, dynamic>?;
          final preferred = habit?['preferred_time']?.toString();
          if (preferred == null || preferred.isEmpty) continue;
          final mins = _minutesFromPreferred(preferred);
          if (mins == null) continue;
          if (earliestPreferredMins == null || mins < earliestPreferredMins) {
            earliestPreferredMins = mins;
            earliestPreferredRaw = preferred;
          }
        }
        if (earliestPreferredMins != null && earliestPreferredRaw != null) {
          final passed = _isPreferredTimePassed(earliestPreferredMins);
          shouldStopSticky = !passed;
          debugPrint(
            '[HomePage] earliestPreferred=$earliestPreferredRaw passed=$passed',
          );
        }
      }

      debugPrint(
        '[HomePage] completedToday=$completedToday shouldStopSticky=$shouldStopSticky',
      );
      await NotificationService.instance.syncStickyDaily(
        completedToday: shouldStopSticky,
        todayLocalIso: todayLocalIso,
      );
    } catch (e) {
      debugPrint('Sticky notification sync skipped: $e');
    }
  }

  Future<void> _refreshAll() async {
    // Home
    ref.invalidate(todayInstancesProvider);
    ref.invalidate(playerStatsProvider);
    ref.invalidate(playerMetricsProvider);

    // Dashboard (fase 5)
    ref.invalidate(dashboardHeatmapProvider);
    ref.invalidate(dashboardWeeklyFocusProvider);
    ref.invalidate(dashboardTopHabitsProvider);

    // Sticky notif (fase 6)
    await _syncStickyNotification();
  }

  Future<void> _handlePendingAction() async {
    try {
      final action = await NotificationService.instance.getPendingAction();
      if (action.isEmpty) return;

      await NotificationService.instance.clearPendingAction();
      if (!mounted) return;

      if (action == 'focus30') {
        final list = await ref.read(instancesRepoProvider).listTodayInstances();
        Map<String, dynamic>? pending;
        for (final item in list) {
          final status = (item['status'] ?? 'pending') as String;
          if (status != 'completed') {
            pending = item;
            break;
          }
        }

        final instanceId = pending?['id']?.toString();
        final habit = pending?['habits'] as Map<String, dynamic>?;
        final title = habit?['title'] ?? 'Focus';
        final expected = (habit?['expected_minutes'] as num?)?.toInt() ?? 30;

        if (instanceId != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FocusPage(
                instanceId: instanceId,
                title: title,
                minutes: expected,
              ),
            ),
          ).then((_) async {
            await _refreshAll();
          });
        }
        return;
      }

      // 'home' and 'complete' currently keep user in Home screen.
    } catch (e) {
      debugPrint('Pending action skipped: $e');
    }
  }

  bool _isPreferredTimePassed(int preferredMins) {
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;
    return nowMins >= preferredMins;
  }

  int? _minutesFromPreferred(String raw) {
    final hhmm = raw.length >= 5 ? raw.substring(0, 5) : raw;
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    final stats = ref.watch(playerStatsProvider);
    final today = ref.watch(todayInstancesProvider);
    final metrics = ref.watch(playerMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeXP'),
        actions: [
          IconButton(
            tooltip: 'Dashboard',
            onPressed: () => context.push('/dashboard'),
            icon: const Icon(Icons.insights),
          ),
          IconButton(
            tooltip: 'Habits',
            onPressed: () => context.push('/habits'),
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await NotificationService.instance.setStickyEnabled(false);
              await NotificationService.instance.stopSticky();
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? 'player'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // 🎮 HUD (XP + Level + Streak)
            stats.when(
              data: (s) {
                final level = s['level'] ?? 1;
                final streak = s['streak'] ?? 0;
                final xpTotal = s['xp_total'] ?? 0;
                final xpIn = s['xp_in_level'] ?? 0;
                final xpToNext = s['xp_to_next'] ?? 0;
                final cost = s['level_cost'] ?? 100;
                final progress = cost == 0
                    ? 0.0
                    : (xpIn / cost).clamp(0.0, 1.0);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL $level',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$xpTotal XP total',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🔥 $streak day streak',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$xpToNext XP to next level'),
                    ],
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(minHeight: 6),
              error: (e, _) => Text('Stats error: $e'),
            ),

            const SizedBox(height: 12),

            // 📊 Metrics (Focus minutes + Consistency + Top habit)
            metrics.when(
              data: (m) {
                final focusToday = m['focus_minutes_today'] ?? 0;
                final focusWeek = m['focus_minutes_week'] ?? 0;
                final consistency = m['consistency_week'] ?? 0;

                final topTitle = (m['top_habit_title'] ?? '') as String;
                final topRate = m['top_habit_rate'] ?? 0;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This Week',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text('🧠 Focus today: $focusToday min'),
                          ),
                          Expanded(
                            child: Text('📅 Focus week: $focusWeek min'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '🎯 Consistency: $consistency/100',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (topTitle.isNotEmpty)
                        Text('🏆 Top habit: $topTitle ($topRate%)')
                      else
                        const Text('🏆 Top habit: -'),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 6, bottom: 6),
                child: LinearProgressIndicator(minHeight: 6),
              ),
              error: (e, _) => Text('Metrics error: $e'),
            ),

            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: () async {
                await ref.read(instancesRepoProvider).ensureTodayInstances();
                await _refreshAll();
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync today missions'),
            ),

            const SizedBox(height: 16),
            const Text(
              'Today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: today.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No missions yet. Create a habit first.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = list[i];
                      final status = (it['status'] ?? 'pending') as String;
                      final habit = it['habits'] as Map<String, dynamic>?;
                      final title = habit?['title'] ?? 'Habit';
                      final expected =
                          (habit?['expected_minutes'] as num?)?.toInt() ?? 30;
                      final instanceId = it['id']?.toString();
                      final done = status == 'completed';

                      return ListTile(
                        title: Text(title),
                        subtitle: Text('Status: $status • ${expected}m'),
                        trailing: done
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Focus 30',
                                    icon: const Icon(Icons.timer),
                                    onPressed: instanceId == null
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FocusPage(
                                                  instanceId: instanceId,
                                                  title: title,
                                                  minutes: expected,
                                                ),
                                              ),
                                            ).then((_) async {
                                              await _refreshAll();
                                            });
                                          },
                                  ),
                                  const SizedBox(width: 6),
                                  FilledButton(
                                    onPressed: instanceId == null
                                        ? null
                                        : () async {
                                            await ref
                                                .read(instancesRepoProvider)
                                                .completeInstance(
                                                  instanceId,
                                                  xp: 10,
                                                );
                                            await _refreshAll();
                                          },
                                    child: const Text('Complete'),
                                  ),
                                ],
                              ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
