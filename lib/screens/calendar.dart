import 'package:material_ui/material_ui.dart';

import '../calendar_math.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'day.dart';

/// Tab 2: a month grid marking the days with any logged set.
class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> with ReloadOnChange {
  Set<DateTime> _trained = const {};
  late DateTime _month = _firstOfMonth(DateTime.now());

  static DateTime _firstOfMonth(DateTime day) => DateTime(day.year, day.month);

  @override
  Future<void> reload() async {
    final trained = await StoreScope.of(context).repo.trainedDays();
    if (!mounted) return;
    setState(() => _trained = trained);
  }

  bool get _isCurrentMonth => _month == _firstOfMonth(DateTime.now());

  void _shift(int months) {
    final next = DateTime(_month.year, _month.month + months);
    if (next.isAfter(_firstOfMonth(DateTime.now()))) return;
    setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final monthCount = trainedInMonth(_trained, _month.year, _month.month);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity > 200) _shift(-1);
              if (velocity < -200) _shift(1);
            },
            child: Panel(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous month',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _shift(-1),
                      ),
                      Expanded(
                        child: Text(
                          formatMonth(_month.year, _month.month),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next month',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _isCurrentMonth ? null : () => _shift(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (final name in const [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ])
                        Expanded(
                          child: Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Palette.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _grid(today),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: monthCount,
                  label: monthCount == 1 ? 'day this month' : 'days this month',
                  highlight: true,
                ),
              ),
              if (_isCurrentMonth) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    value: trainedInWeek(_trained, today),
                    label: 'this week',
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const _Legend(),
        ],
      ),
    );
  }

  Widget _grid(DateTime today) {
    final cells = monthGrid(_month.year, _month.month);
    final rows = <Widget>[];
    for (var start = 0; start < cells.length; start += 7) {
      final week = cells.sublist(start, (start + 7).clamp(0, cells.length));
      rows.add(
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: i < week.length && week[i] != null
                    ? _dayCell(
                        DateTime(_month.year, _month.month, week[i]!),
                        today,
                      )
                    : const SizedBox(height: 46),
              ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _dayCell(DateTime day, DateTime today) {
    final trained = _trained.contains(day);
    final isToday = day == today;
    final future = day.isAfter(today);
    final number = Text(
      '${day.day}',
      style: TextStyle(
        fontSize: 16,
        fontWeight: trained || isToday ? FontWeight.w700 : FontWeight.w400,
        color: trained
            ? Palette.onYellow
            : (future
                  ? Palette.faint
                  : (isToday ? Palette.text : Palette.muted)),
      ),
    );
    final circle = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: trained ? Palette.yellow : null,
        border: isToday ? Border.all(color: Palette.purple, width: 2) : null,
      ),
      child: number,
    );
    final cell = SizedBox(height: 46, child: Center(child: circle));
    if (!trained) return cell;
    return Semantics(
      button: true,
      label: 'Trained on ${formatDay(day)}',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => DayScreen(day: day))),
        child: cell,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final int value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: highlight ? Palette.yellow : Palette.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Palette.muted),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: Palette.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Palette.yellow,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          const Text('Trained', style: style),
          const SizedBox(width: 18),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Palette.purple, width: 2),
            ),
          ),
          const SizedBox(width: 6),
          const Text('Today', style: style),
        ],
      ),
    );
  }
}
