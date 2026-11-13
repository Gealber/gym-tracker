import 'package:sqflite_common/sqlite_api.dart';

import 'models.dart';
import 'stats.dart';

/// Thrown when an exercise name is already taken (case-insensitive).
class DuplicateNameException implements Exception {
  const DuplicateNameException(this.name);

  final String name;

  @override
  String toString() => 'An exercise named "$name" already exists';
}

/// The only owner of SQL in the app. All data lives in one SQLite file.
class Repo {
  Repo._(this._db);

  final Database _db;

  /// Stored in PRAGMA user_version; bump it and add a step in [_upgrade].
  static const schemaVersion = 1;

  /// Opens (creating if needed) the database at [path]. [factory] is
  /// sqflite's on the phone and sqflite_common_ffi's in tests.
  static Future<Repo> open(DatabaseFactory factory, String path) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _upgrade(db, 0, version),
        onUpgrade: _upgrade,
      ),
    );
    return Repo._(db);
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    if (from < 1) {
      await db.execute('''
        CREATE TABLE exercises (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL UNIQUE COLLATE NOCASE,
          created_at INTEGER NOT NULL
        )''');
      await db.execute('''
        CREATE TABLE sets (
          id INTEGER PRIMARY KEY,
          exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
          day TEXT NOT NULL,
          position INTEGER NOT NULL,
          kg REAL NOT NULL,
          reps INTEGER NOT NULL
        )''');
      await db.execute('CREATE INDEX sets_exercise_day ON sets(exercise_id, day)');
      await db.execute('CREATE INDEX sets_day ON sets(day)');
    }
  }

  Future<void> close() => _db.close();

  // Exercises.

  Future<List<Exercise>> exercises() async {
    final rows = await _db.query('exercises', orderBy: 'name COLLATE NOCASE');
    return [for (final r in rows) _exercise(r)];
  }

  /// Adds an exercise. The name is trimmed and must not be empty.
  Future<Exercise> addExercise(String name, {DateTime? now}) async {
    final clean = _cleanName(name);
    try {
      final id = await _db.insert('exercises', {
        'name': clean,
        'created_at': (now ?? DateTime.now()).millisecondsSinceEpoch,
      });
      return Exercise(id: id, name: clean);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateNameException(clean);
      rethrow;
    }
  }

  Future<void> renameExercise(int id, String name) async {
    final clean = _cleanName(name);
    try {
      await _db.update('exercises', {'name': clean},
          where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw DuplicateNameException(clean);
      rethrow;
    }
  }

  /// Deletes the exercise and, through the foreign key, all its sets.
  Future<void> deleteExercise(int id) =>
      _db.delete('exercises', where: 'id = ?', whereArgs: [id]);

  // Sets and sessions.

  /// Replaces everything logged for [exerciseId] on [day] with [sets], in
  /// order. An empty list deletes the day.
  Future<void> saveDay(int exerciseId, DateTime day, List<WorkSet> sets) async {
    for (final s in sets) {
      if (s.kg < 0 || s.reps < 1) {
        throw ArgumentError('invalid set: $s');
      }
    }
    final key = dayKey(day);
    await _db.transaction((txn) async {
      await txn.delete('sets',
          where: 'exercise_id = ? AND day = ?', whereArgs: [exerciseId, key]);
      final batch = txn.batch();
      for (var i = 0; i < sets.length; i++) {
        batch.insert('sets', {
          'exercise_id': exerciseId,
          'day': key,
          'position': i + 1,
          'kg': sets[i].kg,
          'reps': sets[i].reps,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  /// All sessions of an exercise, newest first.
  Future<List<Session>> sessions(int exerciseId) async {
    final rows = await _db.query('sets',
        columns: ['day', 'kg', 'reps'],
        where: 'exercise_id = ?',
        whereArgs: [exerciseId],
        orderBy: 'day DESC, position');
    return _groupSessions(rows);
  }

  /// The sets of one exercise on one day, or null if nothing was logged.
  Future<Session?> session(int exerciseId, DateTime day) async {
    final rows = await _db.query('sets',
        columns: ['day', 'kg', 'reps'],
        where: 'exercise_id = ? AND day = ?',
        whereArgs: [exerciseId, dayKey(day)],
        orderBy: 'position');
    final s = _groupSessions(rows);
    return s.isEmpty ? null : s.first;
  }

  /// The latest session of an exercise strictly before [day].
  Future<Session?> previousSession(int exerciseId, DateTime day) async {
    final last = await _db.query('sets',
        columns: ['day'],
        where: 'exercise_id = ? AND day < ?',
        whereArgs: [exerciseId, dayKey(day)],
        orderBy: 'day DESC',
        limit: 1);
    if (last.isEmpty) return null;
    return session(exerciseId, parseDayKey(last.first['day']! as String));
  }

  /// One summary per exercise: most recently trained first, then the ones
  /// never trained, by name.
  Future<List<ExerciseSummary>> summaries() async {
    final all = await exercises();
    final out = <ExerciseSummary>[];
    for (final e in all) {
      final s = await sessions(e.id);
      out.add(ExerciseSummary(
        exercise: e,
        lastDay: s.isEmpty ? null : s.first.day,
        lastTop: s.isEmpty ? null : topSet(s.first.sets),
        monthChangeKg: changeOver(s),
      ));
    }
    out.sort((a, b) {
      final da = a.lastDay, db = b.lastDay;
      if (da != null && db != null && da != db) return db.compareTo(da);
      if (da == null && db != null) return 1;
      if (da != null && db == null) return -1;
      return a.exercise.name.toLowerCase().compareTo(b.exercise.name.toLowerCase());
    });
    return out;
  }

  // Days across all exercises.

  /// The latest day with any set, or null when nothing is logged.
  Future<DateTime?> lastWorkoutDay() async {
    final rows = await _db.rawQuery('SELECT MAX(day) AS d FROM sets');
    final d = rows.first['d'] as String?;
    return d == null ? null : parseDayKey(d);
  }

  /// Every day with at least one set.
  Future<Set<DateTime>> trainedDays() async {
    final rows = await _db.rawQuery('SELECT DISTINCT day FROM sets');
    return {for (final r in rows) parseDayKey(r['day']! as String)};
  }

  /// Everything done on [day], exercises in the order they were first logged.
  Future<List<DayEntry>> dayLog(DateTime day) async {
    final rows = await _db.rawQuery('''
      SELECT e.id, e.name, s.kg, s.reps
      FROM sets s JOIN exercises e ON e.id = s.exercise_id
      WHERE s.day = ?
      ORDER BY (SELECT MIN(id) FROM sets WHERE exercise_id = e.id AND day = s.day),
               s.position''', [dayKey(day)]);
    final out = <DayEntry>[];
    for (final r in rows) {
      final id = r['id']! as int;
      if (out.isEmpty || out.last.exercise.id != id) {
        out.add(DayEntry(
            exercise: Exercise(id: id, name: r['name']! as String), sets: []));
      }
      out.last.sets.add(_set(r));
    }
    return out;
  }

  /// Every set ever logged, oldest first, for the CSV export.
  Future<List<SetRow>> allSets() async {
    final rows = await _db.rawQuery('''
      SELECT s.day, e.name, s.position, s.kg, s.reps
      FROM sets s JOIN exercises e ON e.id = s.exercise_id
      ORDER BY s.day, e.name COLLATE NOCASE, s.position''');
    return [
      for (final r in rows)
        SetRow(
          day: parseDayKey(r['day']! as String),
          exercise: r['name']! as String,
          position: r['position']! as int,
          set: _set(r),
        ),
    ];
  }

  // Helpers.

  static String _cleanName(String name) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty) throw ArgumentError('exercise name is empty');
    return clean;
  }

  static Exercise _exercise(Map<String, Object?> r) =>
      Exercise(id: r['id']! as int, name: r['name']! as String);

  static WorkSet _set(Map<String, Object?> r) =>
      WorkSet(kg: (r['kg']! as num).toDouble(), reps: r['reps']! as int);

  /// Groups rows already ordered by day then position into sessions.
  static List<Session> _groupSessions(List<Map<String, Object?>> rows) {
    final out = <Session>[];
    String? current;
    for (final r in rows) {
      final key = r['day']! as String;
      if (key != current) {
        out.add(Session(day: parseDayKey(key), sets: []));
        current = key;
      }
      out.last.sets.add(_set(r));
    }
    return out;
  }
}
