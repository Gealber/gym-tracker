import 'format.dart';
import 'models.dart';

/// CSV text for [rows]: header plus one line per set, RFC 4180 quoting,
/// CRLF line ends, kg with '.' as decimal.
String toCsv(List<SetRow> rows) {
  final buffer = StringBuffer('date,exercise,set,kg,reps\r\n');
  for (final row in rows) {
    buffer
      ..write(dayKey(row.day))
      ..write(',')
      ..write(_field(row.exercise))
      ..write(',')
      ..write(row.position)
      ..write(',')
      ..write(formatKg(row.set.kg))
      ..write(',')
      ..write(row.set.reps)
      ..write('\r\n');
  }
  return buffer.toString();
}

/// File name for an export made on [now].
String csvFileName(DateTime now) => 'gym-${dayKey(now)}.csv';

String _field(String value) {
  if (!value.contains(RegExp(r'[",\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
