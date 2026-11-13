import 'package:gym_tracker/calendar_math.dart';
import 'package:test/test.dart';

void main() {
  test('November 2026 starts on Sunday: 6 blanks, then 30 days', () {
    final g = monthGrid(2026, 11);
    expect(g.take(6), everyElement(isNull));
    expect(g[6], 1);
    expect(g.last, 30);
    expect(g.length, 36);
  });

  test('a month starting on Monday has no blanks', () {
    // 1 June 2026 is a Monday.
    expect(monthGrid(2026, 6).first, 1);
  });

  test('February lengths, leap years included', () {
    expect(daysInMonth(2026, 2), 28);
    expect(daysInMonth(2028, 2), 29);
    expect(daysInMonth(2100, 2), 28);
    expect(daysInMonth(2000, 2), 29);
    expect(daysInMonth(2026, 12), 31);
  });

  test('weekStart is the Monday', () {
    expect(weekStart(DateTime(2026, 11, 13)), DateTime(2026, 11, 9));
    expect(weekStart(DateTime(2026, 11, 9)), DateTime(2026, 11, 9));
    expect(weekStart(DateTime(2026, 11, 15)), DateTime(2026, 11, 9));
    // Across a month boundary.
    expect(weekStart(DateTime(2026, 11, 1)), DateTime(2026, 10, 26));
  });

  test('counts for the month and the week', () {
    final trained = {
      DateTime(2026, 10, 30),
      DateTime(2026, 11, 2),
      DateTime(2026, 11, 4),
      DateTime(2026, 11, 6),
      DateTime(2026, 11, 9),
      DateTime(2026, 11, 11),
    };
    expect(trainedInMonth(trained, 2026, 11), 5);
    expect(trainedInMonth(trained, 2026, 10), 1);
    expect(trainedInWeek(trained, DateTime(2026, 11, 13)), 2);
    expect(trainedInWeek(trained, DateTime(2026, 11, 1)), 1);
  });
}
