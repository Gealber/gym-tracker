import 'package:gym_tracker/format.dart';
import 'package:gym_tracker/models.dart';
import 'package:test/test.dart';

void main() {
  test('formatKg drops useless decimals', () {
    expect(formatKg(80), '80');
    expect(formatKg(82.5), '82.5');
    expect(formatKg(1.25), '1.25');
    expect(formatKg(0), '0');
  });

  test('formatChange carries the sign', () {
    expect(formatChange(5), '+5 kg');
    expect(formatChange(-2.5), '-2.5 kg');
    expect(formatChange(0), '0 kg');
  });

  test('parseKg accepts comma or dot, rejects junk and negatives', () {
    expect(parseKg('42,5'), 42.5);
    expect(parseKg(' 40 '), 40);
    expect(parseKg('0'), 0);
    expect(parseKg(''), isNull);
    expect(parseKg('-5'), isNull);
    expect(parseKg('abc'), isNull);
  });

  test('parseReps needs a whole number of at least 1', () {
    expect(parseReps('8'), 8);
    expect(parseReps('0'), isNull);
    expect(parseReps('2.5'), isNull);
    expect(parseReps(''), isNull);
  });

  test('formatDay and formatSet', () {
    expect(formatDay(DateTime(2026, 11, 11)), 'Wed 11 Nov');
    expect(formatDayLong(DateTime(2026, 11, 11)), 'Wednesday 11 Nov');
    expect(formatMonth(2026, 11), 'November 2026');
    expect(formatSet(const WorkSet(kg: 45, reps: 2)), '45 kg x 2');
  });

  test('daysAgo', () {
    final today = DateTime(2026, 11, 13);
    expect(daysAgo(DateTime(2026, 11, 13), today), 'today');
    expect(daysAgo(DateTime(2026, 11, 12), today), 'yesterday');
    expect(daysAgo(DateTime(2026, 11, 11), today), '2 days ago');
  });

  test('daysAgo counts calendar days across a DST change', () {
    // Spring forward in many zones happens between these dates (47 h apart).
    expect(daysAgo(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), '2 days ago');
    // Fall back (49 h apart).
    expect(daysAgo(DateTime(2026, 10, 24), DateTime(2026, 10, 26)), '2 days ago');
  });

  test('dayKey round trip', () {
    expect(dayKey(DateTime(2026, 3, 7)), '2026-03-07');
    expect(parseDayKey('2026-03-07'), DateTime(2026, 3, 7));
  });
}
