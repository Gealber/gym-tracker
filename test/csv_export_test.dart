import 'package:gym_tracker/csv_export.dart';
import 'package:gym_tracker/models.dart';
import 'package:test/test.dart';

void main() {
  test('header and one line per set', () {
    final csv = toCsv([
      SetRow(
        day: DateTime(2026, 11, 11),
        exercise: 'Bench press flat',
        position: 4,
        set: const WorkSet(kg: 45, reps: 2),
      ),
      SetRow(
        day: DateTime(2026, 11, 11),
        exercise: 'Bench press flat',
        position: 5,
        set: const WorkSet(kg: 42.5, reps: 2),
      ),
    ]);
    expect(
      csv,
      'date,exercise,set,kg,reps\r\n'
      '2026-11-11,Bench press flat,4,45,2\r\n'
      '2026-11-11,Bench press flat,5,42.5,2\r\n',
    );
  });

  test('names with commas or quotes are quoted', () {
    final csv = toCsv([
      SetRow(
        day: DateTime(2026, 1, 2),
        exercise: 'Row, "heavy"',
        position: 1,
        set: const WorkSet(kg: 50, reps: 5),
      ),
    ]);
    expect(csv.split('\r\n')[1], '2026-01-02,"Row, ""heavy""",1,50,5');
  });

  test('empty export is just the header', () {
    expect(toCsv(const []), 'date,exercise,set,kg,reps\r\n');
  });

  test('file name', () {
    expect(csvFileName(DateTime(2026, 11, 13, 18, 30)), 'gym-2026-11-13.csv');
  });
}
