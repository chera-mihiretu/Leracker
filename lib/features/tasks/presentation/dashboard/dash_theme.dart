// Dashboard palettes (dark default + light) and an InheritedWidget to read them.
import 'package:flutter/widgets.dart';

@immutable
class DashPalette {
  const DashPalette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.missed,
    required this.rest,
  });

  final bool isDark;
  final Color bg, card, border, text, textMuted, textFaint;
  final Color missed; // heatmap: missed / skipped
  final Color rest; //   heatmap: not scheduled

  static const emerald = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);

  static const dark = DashPalette(
    isDark: true,
    bg: Color(0xFF0B0F17),
    card: Color(0xFF1A2234),
    border: Color(0xFF2A364F),
    text: Color(0xFFF8FAFC),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFF64748B),
    missed: Color(0xFF334155),
    rest: Color(0xFF232D42),
  );

  static const light = DashPalette(
    isDark: false,
    bg: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    missed: Color(0xFFCBD5E1),
    rest: Color(0xFFF1F5F9),
  );
}

class DashTheme extends InheritedWidget {
  const DashTheme({super.key, required this.palette, required super.child});
  final DashPalette palette;

  static DashPalette of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DashTheme>()?.palette ??
      DashPalette.dark;

  @override
  bool updateShouldNotify(DashTheme old) => old.palette != palette;
}

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

/// "SATURDAY, NOV 14"
String headerDate(DateTime d) =>
    '${_weekdays[d.weekday - 1].toUpperCase()}, ${_months[d.month - 1].toUpperCase()} ${d.day}';

/// "Oct 28, 2026"
String longDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// "Wednesday, Oct 28, 2026"
String weekdayLongDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

/// "Fri, Nov 13"
String shortDate(DateTime d) =>
    '${_weekdays[d.weekday - 1].substring(0, 3)}, ${_months[d.month - 1]} ${d.day}';
