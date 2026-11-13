/// An exercise the user defined, e.g. "Bench press flat".
class Exercise {
  const Exercise({required this.id, required this.name});

  final int id;
  final String name;
}

/// One set: a weight lifted for a number of repetitions.
class WorkSet {
  const WorkSet({required this.kg, required this.reps});

  final double kg;
  final int reps;

  @override
  bool operator ==(Object other) =>
      other is WorkSet && other.kg == kg && other.reps == reps;

  @override
  int get hashCode => Object.hash(kg, reps);

  @override
  String toString() => 'WorkSet($kg x $reps)';
}

/// All sets of one exercise done on one calendar day, in the order performed.
class Session {
  const Session({required this.day, required this.sets});

  /// Local calendar day, time part is always midnight.
  final DateTime day;
  final List<WorkSet> sets;
}

/// Summary shown on the home list, one per exercise.
class ExerciseSummary {
  const ExerciseSummary({
    required this.exercise,
    required this.lastDay,
    required this.lastTop,
    required this.monthChangeKg,
  });

  final Exercise exercise;

  /// Null when the exercise has no sets yet.
  final DateTime? lastDay;
  final WorkSet? lastTop;

  /// Heaviest kg of the last session minus the one about a month earlier.
  /// Null when there is no session that old to compare against.
  final double? monthChangeKg;
}

/// One exercise as done on a given day, for the day view.
class DayEntry {
  const DayEntry({required this.exercise, required this.sets});

  final Exercise exercise;
  final List<WorkSet> sets;
}

/// One stored set with its context, for the CSV export.
class SetRow {
  const SetRow({
    required this.day,
    required this.exercise,
    required this.position,
    required this.set,
  });

  final DateTime day;
  final String exercise;

  /// 1-based order within the day.
  final int position;
  final WorkSet set;
}

/// The date part of [t] as a local midnight.
DateTime dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

/// 'YYYY-MM-DD', the form days are stored in.
String dayKey(DateTime day) {
  final m = day.month.toString().padLeft(2, '0');
  final d = day.day.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-$m-$d';
}

/// Inverse of [dayKey].
DateTime parseDayKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}
