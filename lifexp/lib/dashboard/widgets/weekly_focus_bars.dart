// lib/dashboard/widgets/weekly_focus_bars.dart

import 'package:flutter/material.dart';
import '../models.dart';

class WeeklyFocusBars extends StatelessWidget {
  final List<WeeklyFocusRow> rows;

  const WeeklyFocusBars({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    if (rows.isEmpty) {
      return const SizedBox(height: 140, child: Center(child: Text('No data')));
    }

    final maxVal = rows
        .map((e) => e.focusMinutes)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Focus minutes (8 semanas)',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: rows.map((r) {
              final h = 10 + (90 * (r.focusMinutes / maxVal));
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${r.focusMinutes}', style: t.bodySmall),
                      const SizedBox(height: 6),
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_wkLabel(r.weekStart),
                          style: t.bodySmall?.copyWith(color: Colors.grey[600])),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),
        Text('Sesiones finalizadas: ${rows.fold<int>(0, (a, b) => a + b.sessionsCount)}',
            style: t.bodySmall?.copyWith(color: Colors.grey[600])),
      ],
    );
  }

  String _wkLabel(DateTime d) => '${d.month}/${d.day}';
}