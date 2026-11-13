/// An exercise the user defined, e.g. "Bench press".
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

  /// Top-set kg of the last session minus the one about a month earlier.
  /// Null when there is no session that old to compare against.
  final double? monthChangeKg;
}
