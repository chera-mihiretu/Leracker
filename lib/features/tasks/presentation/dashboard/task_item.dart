// The dashboard's task model. Mirrors the backend `TaskItem` interface and
// computes every dashboard metric (due today, streak, cell states).
import 'package:flutter/painting.dart';

import '../task_setup/task_draft.dart';

enum EntryStatus { done, missed }

/// What a heatmap cell shows.
enum CellState { done, missed, rest, pending, future }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

class TaskItem {
  TaskItem({
    required this.id,
    required this.name,
    required this.gridColor,
    this.frequency = Frequency.daily,
    Set<int>? daysOfWeek,
    this.monthDay = 1,
    this.startMinutes,
    this.reminderCount = 1,
    this.includeInMorningReview = true,
    DateTime? createdAt,
    Map<DateTime, EntryStatus>? entries,
  })  : daysOfWeek = daysOfWeek ?? {0, 1, 2, 3, 4, 5, 6},
        createdAt = dateOnly(createdAt ?? DateTime.now()),
        entries = entries ?? {};

  final String id;
  String name;
  Frequency frequency;

  /// 0 = Monday … 6 = Sunday. Weekly tasks use the single day in this set.
  Set<int> daysOfWeek;

  /// Monthly: 1–31, or [kEndOfMonth].
  int monthDay;
  int? startMinutes;
  int reminderCount;
  Color gridColor;
  bool includeInMorningReview;
  final DateTime createdAt;

  /// Keyed by date-only DateTime.
  final Map<DateTime, EntryStatus> entries;

  factory TaskItem.fromDraft(TaskDraft d) => TaskItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: d.name.trim().isEmpty ? 'Untitled habit' : d.name.trim(),
        frequency: d.frequency,
        daysOfWeek: d.frequency == Frequency.weekly ? {d.weekDay} : {...d.days},
        monthDay: d.monthDay,
        startMinutes: d.minutes,
        reminderCount: d.nudges,
        gridColor: d.color,
        includeInMorningReview: d.morningReview,
      );

  // ── Schedule ─────────────────────────────────────────────────────────

  bool isDueOn(DateTime date) {
    switch (frequency) {
      case Frequency.daily:
        return daysOfWeek.contains(date.weekday - 1);
      case Frequency.weekly:
        return daysOfWeek.contains(date.weekday - 1);
      case Frequency.monthly:
        final last = DateTime(date.year, date.month + 1, 0).day;
        final target =
            monthDay == kEndOfMonth ? last : (monthDay > last ? last : monthDay);
        return date.day == target;
    }
  }

  EntryStatus? statusOn(DateTime d) => entries[dateOnly(d)];

  CellState cellState(DateTime day, DateTime today) {
    final d = dateOnly(day);
    if (d.isAfter(today)) return CellState.future;
    final s = entries[d];
    if (s == EntryStatus.done) return CellState.done;
    if (d.isBefore(createdAt) || !isDueOn(d)) {
      return s == EntryStatus.missed ? CellState.missed : CellState.rest;
    }
    if (d == today && s == null) return CellState.pending;
    return CellState.missed;
  }

  bool get isDueToday => isDueOn(dateOnly(DateTime.now()));
  bool get isCompletedToday =>
      entries[dateOnly(DateTime.now())] == EntryStatus.done;

  /// Consecutive completed *scheduled* days. Today (not yet done) and an
  /// unreviewed yesterday don't break the streak.
  int get currentStreak {
    final today = dateOnly(DateTime.now());
    final yesterday = addDays(today, -1);
    var streak = 0;
    for (var i = 0; i < 400; i++) {
      final d = addDays(today, -i);
      if (d.isBefore(createdAt)) break;
      if (!isDueOn(d)) continue;
      final s = entries[d];
      if (s == null &&
          (d == today || (d == yesterday && includeInMorningReview))) {
        continue;
      }
      if (s == EntryStatus.done) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String get streakUnit => switch (frequency) {
        Frequency.daily => 'd',
        Frequency.weekly => 'w',
        Frequency.monthly => 'mo',
      };

  // ── Labels ───────────────────────────────────────────────────────────

  static const _short = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _long = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  String get scheduleLabel {
    switch (frequency) {
      case Frequency.daily:
        final d = daysOfWeek.toList()..sort();
        if (d.length == 7) return 'Every day';
        if (d.length == 5 && d.every((x) => x < 5)) return 'Weekdays';
        if (d.length == 2 && d.every((x) => x >= 5)) return 'Weekends';
        return d.map((x) => _short[x]).join(', ');
      case Frequency.weekly:
        return 'Every ${_long[daysOfWeek.first]}';
      case Frequency.monthly:
        if (monthDay == kEndOfMonth) return 'Month-end';
        return '${TaskDraft.ordinal(monthDay)} of month';
    }
  }

  /// "07:30 AM"
  String? get timeLabel {
    final m = startMinutes;
    if (m == null) return null;
    final h24 = m ~/ 60, min = m % 60;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '${h12.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} '
        '${h24 < 12 ? 'AM' : 'PM'}';
  }

  // ── JSON (matches the backend TaskItem interface) ────────────────────

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'frequencyType': frequency.name,
        'daysOfWeek': (daysOfWeek.toList()..sort()).map((d) => d + 1).toList(),
        if (frequency == Frequency.monthly)
          'monthlyRule': monthDay == kEndOfMonth
              ? 'end'
              : monthDay == 1
                  ? 'start'
                  : '$monthDay',
        if (startMinutes != null)
          'startTime':
              '${(startMinutes! ~/ 60).toString().padLeft(2, '0')}:${(startMinutes! % 60).toString().padLeft(2, '0')}:00',
        'reminderCount': reminderCount,
        // ignore: deprecated_member_use
        'gridColor': '#${(gridColor.value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
        'includeInMorningReview': includeInMorningReview,
        'isCompletedToday': isCompletedToday,
        'isDueToday': isDueToday,
        'currentStreak': currentStreak,
        'historicalEntries': [
          for (final e in entries.entries)
            {'date': _iso(e.key), 'status': e.value.name},
        ],
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) {
    final rule = j['monthlyRule'] as String?;
    final start = j['startTime'] as String?;
    final hex = (j['gridColor'] as String).replaceFirst('#', '');
    return TaskItem(
      id: j['id'] as String,
      name: j['name'] as String,
      frequency: Frequency.values.byName(j['frequencyType'] as String),
      daysOfWeek: {
        for (final d in (j['daysOfWeek'] as List? ?? const [1, 2, 3, 4, 5, 6, 7]))
          (d as int) - 1
      },
      monthDay: rule == null || rule == 'start'
          ? 1
          : rule == 'end'
              ? kEndOfMonth
              : int.parse(rule),
      startMinutes: start == null
          ? null
          : int.parse(start.substring(0, 2)) * 60 + int.parse(start.substring(3, 5)),
      reminderCount: j['reminderCount'] as int? ?? 1,
      gridColor: Color(int.parse('FF$hex', radix: 16)),
      includeInMorningReview: j['includeInMorningReview'] as bool? ?? true,
      entries: {
        for (final e in (j['historicalEntries'] as List? ?? const []))
          DateTime.parse(e['date'] as String):
              EntryStatus.values.byName(e['status'] as String),
      },
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
    );
  }
}
