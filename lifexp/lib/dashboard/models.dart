// lib/dashboard/models.dart

class HeatmapDay {
  final DateTime day;
  final int habitDone;
  final int focusMinutes;
  final int xp;
  final int score; // 0..4

  HeatmapDay({
    required this.day,
    required this.habitDone,
    required this.focusMinutes,
    required this.xp,
    required this.score,
  });

  factory HeatmapDay.fromJson(Map<String, dynamic> json) => HeatmapDay(
        day: DateTime.parse(json['day'] as String),
        habitDone: (json['habit_done'] as num).toInt(),
        focusMinutes: (json['focus_minutes'] as num).toInt(),
        xp: (json['xp'] as num).toInt(),
        score: (json['score'] as num).toInt(),
      );
}

class WeeklyFocusRow {
  final DateTime weekStart;
  final int focusMinutes;
  final int sessionsCount;

  WeeklyFocusRow({
    required this.weekStart,
    required this.focusMinutes,
    required this.sessionsCount,
  });

  factory WeeklyFocusRow.fromJson(Map<String, dynamic> json) => WeeklyFocusRow(
        weekStart: DateTime.parse(json['week_start'] as String),
        focusMinutes: (json['focus_minutes'] as num).toInt(),
        sessionsCount: (json['sessions_count'] as num).toInt(),
      );
}

class TopHabitRow {
  final String habitId;
  final String habitTitle;
  final int total;
  final int completed;
  final double pct;

  TopHabitRow({
    required this.habitId,
    required this.habitTitle,
    required this.total,
    required this.completed,
    required this.pct,
  });

  factory TopHabitRow.fromJson(Map<String, dynamic> json) => TopHabitRow(
        habitId: json['habit_id'] as String,
        habitTitle: (json['habit_title'] ?? '') as String,
        total: (json['total'] as num).toInt(),
        completed: (json['completed'] as num).toInt(),
        pct: (json['pct'] as num).toDouble(),
      );
}