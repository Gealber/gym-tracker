import 'dart:io';

import 'package:gym_tracker/db.dart';
import 'package:gym_tracker/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';

const bench = [
  WorkSet(kg: 30, reps: 8),
  WorkSet(kg: 40, reps: 6),
  WorkSet(kg: 40, reps: 4),
  WorkSet(kg: 45, reps: 2),
  WorkSet(kg: 40, reps: 2),
];

/// Rows in the sets table, read through a second connection.
Future<int> rawSetCount(String path) async {
  final raw = await databaseFactoryFfi.openDatabase(path,
      options: OpenDatabaseOptions(singleInstance: false));
  final n = (await raw.rawQuery('SELECT COUNT(*) AS n FROM sets')).single['n']!;
  await raw.close();
  return n as int;
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late String path;
  late Repo repo;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('gym_db_test');
    path = '${dir.path}/gym.db';
    repo = await Repo.open(databaseFactoryFfi, path);
  });

  tearDown(() async {
    await repo.close();
    dir.deleteSync(recursive: true);
  });

  group('exercises', () {
    test('names are trimmed and unique ignoring case', () async {
      final e = await repo.addExercise('  Bench   press flat ');
      expect(e.name, 'Bench press flat');
      expect(() => repo.addExercise('bench PRESS flat'),
          throwsA(isA<DuplicateNameException>()));
      expect(() => repo.addExercise('   '), throwsArgumentError);
    });

    test('rename to a taken name fails, to a free name works', () async {
      final a = await repo.addExercise('Squat');
      await repo.addExercise('Deadlift');
      expect(() => repo.renameExercise(a.id, 'deadlift'),
          throwsA(isA<DuplicateNameException>()));
      await repo.renameExercise(a.id, 'Back squat');
      expect([for (final e in await repo.exercises()) e.name],
          ['Back squat', 'Deadlift']);
    });

    test('deleting an exercise deletes its sets (foreign keys on)', () async {
      final a = await repo.addExercise('Bench');
      final b = await repo.addExercise('Squat');
      await repo.saveDay(a.id, DateTime(2026, 11, 11), bench);
      await repo.saveDay(b.id, DateTime(2026, 11, 11),
          const [WorkSet(kg: 60, reps: 5)]);
      await repo.deleteExercise(a.id);
      // Count raw rows: allSets() joins exercises and would hide orphans.
      expect(await rawSetCount(path), 1);
      expect((await repo.allSets()).single.exercise, 'Squat');
    });
  });

  group('saveDay', () {
    test('keeps the sets in order', () async {
      final e = await repo.addExercise('Bench');
      await repo.saveDay(e.id, DateTime(2026, 11, 11), bench);
      final s = await repo.session(e.id, DateTime(2026, 11, 11));
      expect(s!.sets, bench);
    });

    test('saving the same day again replaces it', () async {
      final e = await repo.addExercise('Bench');
      final day = DateTime(2026, 11, 11);
      await repo.saveDay(e.id, day, bench);
      await repo.saveDay(e.id, day, const [WorkSet(kg: 50, reps: 1)]);
      final all = await repo.sessions(e.id);
      expect(all.length, 1);
      expect(all.single.sets, const [WorkSet(kg: 50, reps: 1)]);
    });

    test('an empty list deletes the day', () async {
      final e = await repo.addExercise('Bench');
      final day = DateTime(2026, 11, 11);
      await repo.saveDay(e.id, day, bench);
      await repo.saveDay(e.id, day, const []);
      expect(await repo.session(e.id, day), isNull);
      expect(await repo.lastWorkoutDay(), isNull);
    });

    test('rejects zero reps and negative kg, writes nothing', () async {
      final e = await repo.addExercise('Bench');
      final day = DateTime(2026, 11, 11);
      expect(() => repo.saveDay(e.id, day, const [WorkSet(kg: 40, reps: 0)]),
          throwsArgumentError);
      expect(() => repo.saveDay(e.id, day, const [WorkSet(kg: -1, reps: 5)]),
          throwsArgumentError);
      expect(await repo.session(e.id, day), isNull);
    });

    test('0 kg is allowed (bodyweight)', () async {
      final e = await repo.addExercise('Pull up');
      await repo.saveDay(e.id, DateTime(2026, 11, 11),
          const [WorkSet(kg: 0, reps: 8)]);
      expect((await repo.sessions(e.id)).single.sets.single.kg, 0);
    });
  });

  group('reading back', () {
    test('sessions newest first, previousSession strictly before', () async {
      final e = await repo.addExercise('Bench');
      await repo.saveDay(e.id, DateTime(2026, 11, 4),
          const [WorkSet(kg: 42.5, reps: 3)]);
      await repo.saveDay(e.id, DateTime(2026, 11, 11), bench);
      final all = await repo.sessions(e.id);
      expect([for (final s in all) s.day],
          [DateTime(2026, 11, 11), DateTime(2026, 11, 4)]);

      final prevToday = await repo.previousSession(e.id, DateTime(2026, 11, 13));
      expect(prevToday!.day, DateTime(2026, 11, 11));
      expect(prevToday.sets, bench);
      final prevOf11 = await repo.previousSession(e.id, DateTime(2026, 11, 11));
      expect(prevOf11!.day, DateTime(2026, 11, 4));
      expect(await repo.previousSession(e.id, DateTime(2026, 11, 4)), isNull);
    });

    test('summaries: most recent first, never trained last', () async {
      final bench1 = await repo.addExercise('Bench');
      final squat = await repo.addExercise('Squat');
      await repo.addExercise('Row');
      await repo.saveDay(bench1.id, DateTime(2026, 10, 8),
          const [WorkSet(kg: 40, reps: 5)]);
      await repo.saveDay(bench1.id, DateTime(2026, 11, 11), bench);
      await repo.saveDay(squat.id, DateTime(2026, 11, 9),
          const [WorkSet(kg: 60, reps: 5)]);

      final s = await repo.summaries();
      expect([for (final x in s) x.exercise.name], ['Bench', 'Squat', 'Row']);
      expect(s[0].lastDay, DateTime(2026, 11, 11));
      expect(s[0].lastTop, const WorkSet(kg: 45, reps: 2));
      expect(s[0].monthChangeKg, 5);
      expect(s[1].monthChangeKg, isNull);
      expect(s[2].lastDay, isNull);
      expect(s[2].lastTop, isNull);
    });

    test('trained days, last workout and the day log', () async {
      final b = await repo.addExercise('Bench');
      final l = await repo.addExercise('Lat pulldown');
      await repo.saveDay(l.id, DateTime(2026, 11, 11),
          const [WorkSet(kg: 50, reps: 10)]);
      await repo.saveDay(b.id, DateTime(2026, 11, 11), bench);
      await repo.saveDay(b.id, DateTime(2026, 11, 4),
          const [WorkSet(kg: 42.5, reps: 3)]);

      expect(await repo.trainedDays(),
          {DateTime(2026, 11, 4), DateTime(2026, 11, 11)});
      expect(await repo.lastWorkoutDay(), DateTime(2026, 11, 11));

      final log = await repo.dayLog(DateTime(2026, 11, 11));
      // Order logged: lat pulldown first, then bench.
      expect([for (final d in log) d.exercise.name], ['Lat pulldown', 'Bench']);
      expect(log[1].sets, bench);
      expect(await repo.dayLog(DateTime(2026, 11, 12)), isEmpty);
    });

    test('allSets oldest first with positions', () async {
      final b = await repo.addExercise('Bench');
      await repo.saveDay(b.id, DateTime(2026, 11, 11), bench);
      await repo.saveDay(b.id, DateTime(2026, 11, 4),
          const [WorkSet(kg: 42.5, reps: 3)]);
      final rows = await repo.allSets();
      expect(rows.first.day, DateTime(2026, 11, 4));
      expect([for (final r in rows.skip(1)) r.position], [1, 2, 3, 4, 5]);
    });
  });

  test('data survives reopening; schema version is stored', () async {
    final e = await repo.addExercise('Bench');
    await repo.saveDay(e.id, DateTime(2026, 11, 11), bench);
    await repo.close();
    repo = await Repo.open(databaseFactoryFfi, path);
    expect((await repo.sessions(e.id)).single.sets, bench);

    final raw = await databaseFactoryFfi.openDatabase(path,
        options: OpenDatabaseOptions(singleInstance: false, readOnly: true));
    final v = await raw.rawQuery('PRAGMA user_version');
    expect(v.single.values.single, Repo.schemaVersion);
    await raw.close();
  });
}
