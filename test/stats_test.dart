import 'package:gym_tracker/models.dart';
import 'package:gym_tracker/stats.dart';
import 'package:test/test.dart';

List<WorkSet> sets(List<List<num>> pairs) => [
  for (final pair in pairs)
    WorkSet(kg: pair[0].toDouble(), reps: pair[1].toInt()),
];

Session session(DateTime day, List<List<num>> pairs) =>
    Session(day: day, sets: sets(pairs));

void main() {
  group('topSet', () {
    test('picks the heaviest set of the bench example', () {
      final logged = sets([
        [30, 8],
        [40, 6],
        [40, 4],
        [45, 2],
        [40, 2],
      ]);
      expect(topSet(logged), const WorkSet(kg: 45, reps: 2));
    });

    test('on equal weight takes more reps', () {
      final logged = sets([
        [40, 4],
        [40, 6],
        [40, 2],
      ]);
      expect(topSet(logged), const WorkSet(kg: 40, reps: 6));
    });
  });

  group('chartPoints', () {
    final all = [
      session(DateTime(2026, 11, 11), [
        [30, 8],
        [45, 2],
      ]),
      session(DateTime(2026, 10, 1), [
        [40, 5],
      ]),
      session(DateTime(2026, 11, 4), [
        [42.5, 3],
      ]),
      Session(day: DateTime(2026, 11, 5), sets: const []),
    ];

    test('one point per day, oldest first, empty days skipped', () {
      final points = chartPoints(all);
      expect(
        [for (final point in points) point.day],
        [DateTime(2026, 10, 1), DateTime(2026, 11, 4), DateTime(2026, 11, 11)],
      );
      expect([for (final point in points) point.kg], [40, 42.5, 45]);
      expect(points.last.top, const WorkSet(kg: 45, reps: 2));
    });

    test('since keeps days on or after it', () {
      final points = chartPoints(all, since: DateTime(2026, 11, 4));
      expect(points.length, 2);
      expect(points.first.day, DateTime(2026, 11, 4));
    });
  });

  group('changeOver', () {
    test('last minus latest session at least 30 days older', () {
      final all = [
        session(DateTime(2026, 10, 1), [
          [35, 5],
        ]),
        session(DateTime(2026, 10, 8), [
          [40, 5],
        ]),
        session(DateTime(2026, 10, 20), [
          [42.5, 3],
        ]),
        session(DateTime(2026, 11, 11), [
          [45, 2],
        ]),
      ];
      // Cutoff 12 Oct: 8 Oct is the latest session on or before it.
      expect(changeOver(all), 5);
    });

    test('null when no session is a month old', () {
      final all = [
        session(DateTime(2026, 11, 1), [
          [40, 5],
        ]),
        session(DateTime(2026, 11, 11), [
          [45, 2],
        ]),
      ];
      expect(changeOver(all), isNull);
      expect(
        changeOver([
          session(DateTime(2026, 11, 11), [
            [45, 2],
          ]),
        ]),
        isNull,
      );
    });

    test(
      'a session exactly 30 calendar days back counts across a DST change',
      () {
        // Clocks spring forward between these dates in many DST zones, so the
        // two midnights are 30 days minus one hour apart; a 30 * 24 h cutoff
        // lands at 23:00 the day before and drops 21 Mar.
        final all = [
          session(DateTime(2026, 3, 21), [
            [40, 5],
          ]),
          session(DateTime(2026, 4, 20), [
            [45, 2],
          ]),
        ];
        expect(changeOver(all), 5);
      },
    );
  });
}
