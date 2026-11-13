import 'models.dart';

/// Heaviest set of a session; on equal weight the one with more reps.
/// Example: 30x8, 40x6, 40x4, 45x2, 40x2 -> 45x2.
WorkSet topSet(List<WorkSet> sets) {
  var best = sets.first;
  for (final s in sets.skip(1)) {
    if (s.kg > best.kg || (s.kg == best.kg && s.reps > best.reps)) best = s;
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
    for (final s in sessions)
      if (s.sets.isNotEmpty && (since == null || !s.day.isBefore(since)))
        ChartPoint(s.day, topSet(s.sets)),
  ];
  points.sort((a, b) => a.day.compareTo(b.day));
  return points;
}

/// Top kg of the latest session minus the top kg of the latest session that is
/// at least [window] older. Null when no session is that old.
double? changeOver(
  List<Session> sessions, {
  Duration window = const Duration(days: 30),
}) {
  final points = chartPoints(sessions);
  if (points.length < 2) return null;
  final last = points.last;
  final cutoff = last.day.subtract(window);
  ChartPoint? before;
  for (final p in points) {
    if (p.day.isAfter(cutoff)) break;
    before = p;
  }
  if (before == null) return null;
  return last.kg - before.kg;
}
