import 'models.dart';

/// 80 -> "80", 82.5 -> "82.5", 1.25 -> "1.25". Always '.' as decimal.
String formatKg(double kg) {
  if (kg == kg.roundToDouble()) return kg.toInt().toString();
  var s = kg.toStringAsFixed(2);
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// "45 kg x 2".
String formatSet(WorkSet s) => '${formatKg(s.kg)} kg x ${s.reps}';

/// "45 x 2", for compact lists of sets.
String formatSetShort(WorkSet s) => '${formatKg(s.kg)} x ${s.reps}';

/// "+5 kg", "-2.5 kg", "0 kg".
String formatChange(double kg) {
  final sign = kg > 0 ? '+' : (kg < 0 ? '-' : '');
  return '$sign${formatKg(kg.abs())} kg';
}

/// Parses a kg field: accepts ',' or '.' as decimal, rejects negatives.
double? parseKg(String text) {
  final v = double.tryParse(text.trim().replaceAll(',', '.'));
  if (v == null || v < 0 || v.isNaN || v.isInfinite) return null;
  return v;
}

/// Parses a reps field: whole number >= 1.
int? parseReps(String text) {
  final v = int.tryParse(text.trim());
  if (v == null || v < 1) return null;
  return v;
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "Wed 11 Nov".
String formatDay(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "Wednesday 11 Nov".
String formatDayLong(DateTime d) =>
    '${_weekdaysLong[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "November 2026".
String formatMonth(int year, int month) => '${_monthsLong[month - 1]} $year';

/// Short month name for chart labels, "Nov".
String monthShort(int month) => _months[month - 1];

/// "today", "yesterday", "3 days ago". [today] is a local midnight.
String daysAgo(DateTime day, DateTime today) {
  // Rounded: across a DST change two midnights are 23 or 25 hours apart.
  final n = (dateOnly(today).difference(dateOnly(day)).inHours / 24).round();
  if (n <= 0) return 'today';
  if (n == 1) return 'yesterday';
  return '$n days ago';
}
