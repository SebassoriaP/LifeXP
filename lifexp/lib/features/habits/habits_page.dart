import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers.dart';

final habitsListProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(habitsRepoProvider);
  return repo.listAllHabits();
});

class HabitsPage extends ConsumerWidget {
  const HabitsPage({super.key});

  void _handleHorizontalSwipe(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 250) return;

    if (velocity > 0) {
      context.go('/dashboard');
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final input = await _showCreateDialog(context);
          if (input == null || input.title.trim().isEmpty) return;

          final habitId = await ref
              .read(habitsRepoProvider)
              .createHabit(
                title: input.title.trim(),
                scheduleType: 'weekly',
                daysOfWeek: input.daysOfWeek,
                preferredTime: input.preferredTime,
                expectedMinutes: input.expectedMinutes,
                windowStart: '13:00:00',
                windowEnd: '22:00:00',
              );
          // Run the general RPC sync first, then directly ensure today's
          // instance for this new habit in case the RPC misses it.
          await ref.read(instancesRepoProvider).ensureTodayInstances();
          await ref
              .read(instancesRepoProvider)
              .ensureInstanceForToday(
                habitId: habitId,
                daysOfWeek: input.daysOfWeek,
              );
          ref.invalidate(habitsListProvider);
          ref.invalidate(todayInstancesProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) =>
            _handleHorizontalSwipe(context, details),
        child: habits.when(
          data: (list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final h = list[i];
              final active = h['active'] == true;
              final preferredTime =
                  h['preferred_time']?.toString() ?? '--:--:--';
              final expected = (h['expected_minutes'] as num?)?.toInt() ?? 30;
              return Card(
                key: ValueKey(h['id']?.toString()),
                clipBehavior: Clip.hardEdge,
                child: ListTile(
                  onTap: () => _openEditHabit(context, ref, h),
                  title: Text(h['title'] ?? ''),
                  subtitle: Text(
                    '${active ? 'Active' : 'Inactive'} • ${expected}m • ${_hhmm(preferredTime)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openEditHabit(context, ref, h),
                      ),
                      IconButton(
                        tooltip: 'Eliminar',
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete habit?'),
                              content: const Text(
                                'This will remove it from your list (history stays).',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;

                          final habitId = h['id']?.toString();
                          if (habitId == null) return;
                          await ref
                              .read(habitsRepoProvider)
                              .deleteHabit(habitId);
                          await ref
                              .read(instancesRepoProvider)
                              .ensureTodayInstances();
                          ref.invalidate(habitsListProvider);
                          ref.invalidate(todayInstancesProvider);
                        },
                      ),
                      Switch(
                        value: active,
                        onChanged: (v) async {
                          await ref
                              .read(habitsRepoProvider)
                              .setHabitActive(h['id'], v);
                          await ref
                              .read(instancesRepoProvider)
                              .ensureTodayInstances();
                          ref.invalidate(habitsListProvider);
                          ref.invalidate(todayInstancesProvider);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemCount: list.length,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Future<_HabitCreateInput?> _showCreateDialog(BuildContext context) async {
    final c = TextEditingController();
    var selectedDays = <int>{1, 2, 3, 4, 5};
    var preferred = const TimeOfDay(hour: 18, minute: 0);
    var expectedMinutes = 30;

    return showDialog<_HabitCreateInput>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('New habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: c,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: '1 LeetCode daily',
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Days',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _dayChip('D', 0, selectedDays, setStateDialog),
                    _dayChip('L', 1, selectedDays, setStateDialog),
                    _dayChip('M', 2, selectedDays, setStateDialog),
                    _dayChip('X', 3, selectedDays, setStateDialog),
                    _dayChip('J', 4, selectedDays, setStateDialog),
                    _dayChip('V', 5, selectedDays, setStateDialog),
                    _dayChip('S', 6, selectedDays, setStateDialog),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Preferred time',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: preferred,
                        );
                        if (picked == null) return;
                        setStateDialog(() => preferred = picked);
                      },
                      child: Text(preferred.format(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Expected minutes: $expectedMinutes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Slider(
                  min: 10,
                  max: 120,
                  divisions: 22,
                  value: expectedMinutes.toDouble(),
                  label: '$expectedMinutes',
                  onChanged: (v) {
                    setStateDialog(() => expectedMinutes = v.round());
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = c.text.trim();
                if (title.isEmpty || selectedDays.isEmpty) return;
                final hh = preferred.hour.toString().padLeft(2, '0');
                final mm = preferred.minute.toString().padLeft(2, '0');
                Navigator.pop(
                  context,
                  _HabitCreateInput(
                    title: title,
                    daysOfWeek: selectedDays.toList()..sort(),
                    preferredTime: '$hh:$mm:00',
                    expectedMinutes: expectedMinutes,
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditHabit(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> habit,
  ) async {
    final titleCtrl = TextEditingController(
      text: (habit['title'] ?? '') as String,
    );
    var active = (habit['active'] ?? true) as bool;

    final dbDays = (habit['days_of_week'] as List<dynamic>?) ?? <dynamic>[];
    final daysSelected = List<bool>.filled(7, false);
    for (final d in dbDays) {
      final day = (d as num).toInt();
      if (day >= 0 && day <= 6) daysSelected[day] = true;
    }
    if (!daysSelected.contains(true)) {
      for (final day in [1, 2, 3, 4, 5]) {
        daysSelected[day] = true;
      }
    }

    final prefStr = (habit['preferred_time'] ?? '18:00:00').toString();
    final prefParts = prefStr.split(':');
    final prefH =
        int.tryParse(prefParts.isNotEmpty ? prefParts[0] : '18') ?? 18;
    final prefM = int.tryParse(prefParts.length > 1 ? prefParts[1] : '0') ?? 0;
    var preferredTime = TimeOfDay(hour: prefH, minute: prefM);

    var expectedMinutes = (habit['expected_minutes'] as num?)?.toInt() ?? 30;
    final habitId = habit['id']?.toString();
    if (habitId == null) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Edit habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: active,
                  onChanged: (v) => setStateDialog(() => active = v),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Days',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    _dayChoiceChip('D', 0, daysSelected, setStateDialog),
                    _dayChoiceChip('L', 1, daysSelected, setStateDialog),
                    _dayChoiceChip('M', 2, daysSelected, setStateDialog),
                    _dayChoiceChip('X', 3, daysSelected, setStateDialog),
                    _dayChoiceChip('J', 4, daysSelected, setStateDialog),
                    _dayChoiceChip('V', 5, daysSelected, setStateDialog),
                    _dayChoiceChip('S', 6, daysSelected, setStateDialog),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Preferred time: ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(_timeToHHmm(preferredTime)),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: preferredTime,
                        );
                        if (picked == null) return;
                        setStateDialog(() => preferredTime = picked);
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Expected minutes: $expectedMinutes',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: expectedMinutes.toDouble().clamp(5, 240),
                  min: 5,
                  max: 240,
                  divisions: 47,
                  label: '$expectedMinutes',
                  onChanged: (v) {
                    setStateDialog(
                      () => expectedMinutes = ((v / 5).round() * 5),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                final days = _daysFromBools(daysSelected);
                await ref
                    .read(habitsRepoProvider)
                    .updateHabit(
                      habitId: habitId,
                      title: title,
                      active: active,
                      daysOfWeek: days,
                      preferredTime: _toTimeStr(preferredTime),
                      expectedMinutes: expectedMinutes,
                    );
                await ref.read(instancesRepoProvider).ensureTodayInstances();
                ref.invalidate(habitsListProvider);
                ref.invalidate(todayInstancesProvider);

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _dayChip(
    String label,
    int value,
    Set<int> selected,
    void Function(void Function()) setStateDialog,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected.contains(value),
      onSelected: (on) {
        setStateDialog(() {
          if (on) {
            selected.add(value);
          } else {
            selected.remove(value);
          }
        });
      },
    );
  }

  static String _hhmm(String value) {
    if (value.length < 5) return value;
    return value.substring(0, 5);
  }

  static Widget _dayChoiceChip(
    String label,
    int idx,
    List<bool> selected,
    void Function(void Function()) setStateDialog,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selected[idx],
      onSelected: (v) => setStateDialog(() => selected[idx] = v),
    );
  }

  static List<int> _daysFromBools(List<bool> selected) {
    final out = <int>[];
    for (var i = 0; i < selected.length; i++) {
      if (selected[i]) out.add(i);
    }
    if (out.isEmpty) return <int>[1, 2, 3, 4, 5, 6, 0];
    return out;
  }

  static String _toTimeStr(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  static String _timeToHHmm(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _HabitCreateInput {
  _HabitCreateInput({
    required this.title,
    required this.daysOfWeek,
    required this.preferredTime,
    required this.expectedMinutes,
  });

  final String title;
  final List<int> daysOfWeek;
  final String preferredTime;
  final int expectedMinutes;
}
