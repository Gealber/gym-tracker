/// Pure date helpers for the calendar tab. Weeks start on Monday.
library;

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Cells of a Monday-first month grid: null for the blanks before day 1,
/// then 1..daysInMonth. No trailing blanks.
List<int?> monthGrid(int year, int month) {
  // DateTime.weekday: Monday = 1 ... Sunday = 7.
  final leading = DateTime(year, month, 1).weekday - 1;
  return [
    for (var i = 0; i < leading; i++) null,
    for (var d = 1; d <= daysInMonth(year, month); d++) d,
  ];
}

/// Monday of the week holding [day], at midnight.
DateTime weekStart(DateTime day) =>
    DateTime(day.year, day.month, day.day - (day.weekday - 1));

/// How many of [trained] fall in the given month.
int trainedInMonth(Set<DateTime> trained, int year, int month) =>
    trained.where((d) => d.year == year && d.month == month).length;

/// How many of [trained] fall in the Monday-to-Sunday week holding [today].
int trainedInWeek(Set<DateTime> trained, DateTime today) {
  final start = weekStart(today);
  final end = DateTime(start.year, start.month, start.day + 7);
  return trained.where((d) => !d.isBefore(start) && d.isBefore(end)).length;
}
