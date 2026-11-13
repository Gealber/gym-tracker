import 'models.dart';

/// 80 -> "80", 82.5 -> "82.5", 1.25 -> "1.25". Always '.' as decimal.
String formatKg(double kg) {
  if (kg == kg.roundToDouble()) return kg.toInt().toString();
  var text = kg.toStringAsFixed(2);
  while (text.endsWith('0')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

/// "45 kg x 2".
String formatSet(WorkSet set) => '${formatKg(set.kg)} kg x ${set.reps}';

/// "45 x 2", for compact lists of sets.
String formatSetShort(WorkSet set) => '${formatKg(set.kg)} x ${set.reps}';

/// "+5 kg", "-2.5 kg", "0 kg".
String formatChange(double kg) {
  final sign = kg > 0 ? '+' : (kg < 0 ? '-' : '');
  return '$sign${formatKg(kg.abs())} kg';
}

/// Parses a kg field: accepts ',' or '.' as decimal, rejects negatives.
double? parseKg(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || value < 0 || value.isNaN || value.isInfinite) {
    return null;
  }
  return value;
}

/// Parses a reps field: whole number >= 1.
int? parseReps(String text) {
  final value = int.tryParse(text.trim());
  if (value == null || value < 1) return null;
  return value;
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdaysLong = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _monthsLong = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// "Wed 11 Nov".
String formatDay(DateTime day) =>
    '${_weekdays[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';

/// "Wednesday 11 Nov".
String formatDayLong(DateTime day) =>
    '${_weekdaysLong[day.weekday - 1]} ${day.day} ${_months[day.month - 1]}';

/// "November 2026".
String formatMonth(int year, int month) => '${_monthsLong[month - 1]} $year';

/// Short month name for chart labels, "Nov".
String monthShort(int month) => _months[month - 1];

/// "today", "yesterday", "3 days ago". [today] is a local midnight.
String daysAgo(DateTime day, DateTime today) {
  // Rounded: across a DST change two midnights are 23 or 25 hours apart.
  final days = (dateOnly(today).difference(dateOnly(day)).inHours / 24).round();
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}
