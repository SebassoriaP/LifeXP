// lib/dashboard/widgets/heatmap_grid.dart

import 'package:flutter/material.dart';
import '../models.dart';

class HeatmapGrid extends StatelessWidget {
  final List<HeatmapDay> days;
  final double cell;
  final double gap;

  const HeatmapGrid({
    super.key,
    required this.days,
    this.cell = 10,
    this.gap = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('No data')));
    }

    final sortedDays = [...days]..sort((a, b) => a.day.compareTo(b.day));
    final byDate = {for (final d in sortedDays) _dateOnly(d.day): d};

    final start = _dateOnly(sortedDays.first.day);
    final end = _dateOnly(sortedDays.last.day);
    final startMonday = start.subtract(Duration(days: start.weekday - 1));

    final totalDays = end.difference(startMonday).inDays + 1;
    final totalWeeks = (totalDays / 7).ceil();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(totalWeeks, (w) {
          return Padding(
            padding: EdgeInsets.only(right: gap),
            child: Column(
              children: List.generate(7, (r) {
                final day = startMonday.add(Duration(days: w * 7 + r));
                final d = byDate[_dateOnly(day)];
                final score = (d?.score ?? 0).clamp(0, 4);
                return Tooltip(
                  message: d == null
                      ? '${day.year}-${day.month}-${day.day}: no data'
                      : '${day.year}-${day.month}-${day.day}  '
                            'score=${d.score}  habits=${d.habitDone}  '
                            'focus=${d.focusMinutes}m  xp=${d.xp}',
                  child: Container(
                    margin: EdgeInsets.only(bottom: gap),
                    width: cell,
                    height: cell,
                    decoration: BoxDecoration(
                      color: _scoreColor(context, score),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Color _scoreColor(BuildContext context, int score) {
    final base = Theme.of(context).colorScheme.primary;
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;

    if (score <= 0) return bg;
    if (score == 1) return Color.lerp(bg, base, 0.30) ?? base;
    if (score == 2) return Color.lerp(bg, base, 0.50) ?? base;
    if (score == 3) return Color.lerp(bg, base, 0.72) ?? base;
    return base;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
