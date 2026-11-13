import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models.dart';
import '../stats.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/pictogram.dart';
import '../widgets/progress_chart.dart';
import 'log_workout.dart';

enum _Range {
  m3('3M', 3),
  m6('6M', 6),
  y1('1Y', 12),
  all('All', 0);

  const _Range(this.label, this.months);

  final String label;
  final int months;
}

/// Chart of the heaviest set per day plus the full history of an exercise.
class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with ReloadOnChange {
  List<Session>? _sessions;
  var _range = _Range.m3;

  @override
  Future<void> reload() async {
    final sessions = await StoreScope.of(
      context,
    ).repo.sessions(widget.exercise.id);
    if (!mounted) return;
    setState(() => _sessions = sessions);
  }

  void _log(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LogWorkoutScreen(exercise: widget.exercise, day: day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _sessions;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ExerciseTile(
              catalogId: widget.exercise.catalogId,
              name: widget.exercise.name,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.exercise.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _log(dateOnly(DateTime.now())),
        icon: const Icon(Icons.add),
        label: const Text(
          'Log workout',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: sessions == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _chartCard(sessions),
                ),
                if (sessions.isNotEmpty) const SectionLabel('History'),
                for (final session in sessions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _SessionCard(
                      session: session,
                      onTap: () => _log(session.day),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _chartCard(List<Session> sessions) {
    if (sessions.isEmpty) {
      return const Panel(
        padding: EdgeInsets.all(24),
        child: Text(
          'No sets yet. Tap "Log workout" after your first session and the '
          'chart starts here.',
          style: TextStyle(color: Palette.muted, fontSize: 15),
        ),
      );
    }
    final today = dateOnly(DateTime.now());
    final allPoints = chartPoints(sessions);
    final first = allPoints.first.day;
    final from = _range == _Range.all
        ? first
        : DateTime(today.year, today.month - _range.months, today.day);
    final points = _range == _Range.all
        ? allPoints
        : chartPoints(sessions, since: from);
    final latest = allPoints.last;
    final change = changeOver(sessions);

    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Heaviest set per day',
                        style: TextStyle(fontSize: 13, color: Palette.muted),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${formatKg(latest.kg)} kg',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: ' x ${latest.top.reps}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Palette.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (change != null && change != 0)
                  ChangeBadge(
                    text: '${formatChange(change)} vs a month ago',
                    up: change > 0,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ProgressChart(
            points: points,
            from: from.isBefore(first) && _range == _Range.all ? first : from,
            to: today.isAfter(latest.day) ? today : latest.day,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final range in _Range.values) ...[
                if (range != _Range.values.first) const SizedBox(width: 8),
                Expanded(child: _rangeButton(range)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeButton(_Range range) {
    final on = range == _range;
    return OutlinedButton(
      onPressed: () => setState(() => _range = range),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        backgroundColor: on ? Palette.purpleChip : Colors.transparent,
        foregroundColor: on ? Palette.purpleChipText : Palette.muted,
        side: BorderSide(color: on ? Palette.purple : Palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(
          fontSize: 14,
          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      child: Text(range.label),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final top = topSet(session.sets);
    final topIndex = session.sets.indexOf(top);
    final count = session.sets.length;
    return Panel(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDay(session.day),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$count ${count == 1 ? 'set' : 'sets'} - top ${formatKg(top.kg)} kg',
                style: const TextStyle(fontSize: 13, color: Palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < count; i++)
                SetChip(
                  text: formatSetShort(session.sets[i]),
                  highlight: i == topIndex,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
