import 'format.dart';
import 'models.dart';

/// CSV text for [rows]: header plus one line per set, RFC 4180 quoting,
/// CRLF line ends, kg with '.' as decimal.
String toCsv(List<SetRow> rows) {
  final b = StringBuffer('date,exercise,set,kg,reps\r\n');
  for (final r in rows) {
    b
      ..write(dayKey(r.day))
      ..write(',')
      ..write(_field(r.exercise))
      ..write(',')
      ..write(r.position)
      ..write(',')
      ..write(formatKg(r.set.kg))
      ..write(',')
      ..write(r.set.reps)
      ..write('\r\n');
  }
  return b.toString();
}

/// File name for an export made on [now].
String csvFileName(DateTime now) => 'gym-${dayKey(now)}.csv';

String _field(String s) {
  if (!s.contains(RegExp(r'[",\r\n]'))) return s;
  return '"${s.replaceAll('"', '""')}"';
}
