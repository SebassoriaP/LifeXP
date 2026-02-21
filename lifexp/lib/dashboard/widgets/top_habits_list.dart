// lib/dashboard/widgets/top_habits_list.dart

import 'package:flutter/material.dart';
import '../models.dart';

class TopHabitsList extends StatelessWidget {
  final List<TopHabitRow> rows;

  const TopHabitsList({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    if (rows.isEmpty) {
      return const SizedBox(height: 160, child: Center(child: Text('No habits yet')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top hábitos (30 días)',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...rows.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.habitTitle,
                            style: t.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text('${r.pct.toStringAsFixed(1)}%',
                          style: t.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (r.pct / 100).clamp(0, 1),
                  ),
                  const SizedBox(height: 4),
                  Text('${r.completed}/${r.total} completadas',
                      style:
                          t.bodySmall?.copyWith(color: Colors.grey[600])),
                ],
              ),
            )),
      ],
    );
  }
}