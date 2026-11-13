import 'models.dart';

/// Heaviest set of a session; on equal weight the one with more reps.
/// Example: 30x8, 40x6, 40x4, 45x2, 40x2 -> 45x2.
WorkSet topSet(List<WorkSet> sets) {
  var best = sets.first;
  for (final set in sets.skip(1)) {
    if (set.kg > best.kg || (set.kg == best.kg && set.reps > best.reps)) {
      best = set;
    }
  }
  return best;
}

/// A point on the progress chart: the top set actually lifted that day.
class ChartPoint {
  const ChartPoint(this.day, this.top);

  final DateTime day;
  final WorkSet top;

  double get kg => top.kg;
}

/// Chart points for [sessions] (any order), oldest first, only days on or
/// after [since] when given. Sessions without sets are skipped.
List<ChartPoint> chartPoints(List<Session> sessions, {DateTime? since}) {
  final points = <ChartPoint>[
    for (final session in sessions)
      if (session.sets.isNotEmpty &&
          (since == null || !session.day.isBefore(since)))
        ChartPoint(session.day, topSet(session.sets)),
  ];
  points.sort((a, b) => a.day.compareTo(b.day));
  return points;
}

/// Top kg of the latest session minus the top kg of the latest session that is
/// at least [days] calendar days older. Null when no session is that old.
double? changeOver(List<Session> sessions, {int days = 30}) {
  final points = chartPoints(sessions);
  if (points.length < 2) return null;
  final last = points.last;
  // Calendar arithmetic, not a Duration: across a DST change 30 * 24 h lands an
  // hour off midnight and would wrongly include or exclude the boundary day.
  final cutoff = DateTime(last.day.year, last.day.month, last.day.day - days);
  ChartPoint? before;
  for (final point in points) {
    if (point.day.isAfter(cutoff)) break;
    before = point;
  }
  if (before == null) return null;
  return last.kg - before.kg;
}
