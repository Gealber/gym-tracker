import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'log_workout.dart';

/// Read-only view of everything done on one day.
class DayScreen extends StatefulWidget {
  const DayScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> with ReloadOnChange {
  List<DayEntry>? _entries;

  @override
  Future<void> reload() async {
    final entries = await StoreScope.of(context).repo.dayLog(widget.day);
    if (!mounted) return;
    setState(() => _entries = entries);
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final setCount =
        entries?.fold<int>(0, (sum, entry) => sum + entry.sets.length) ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatDayLong(widget.day),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            if (entries != null && entries.isNotEmpty)
              Text(
                '${entries.length} ${entries.length == 1 ? 'exercise' : 'exercises'}'
                ' - $setCount ${setCount == 1 ? 'set' : 'sets'}',
                style: const TextStyle(fontSize: 13, color: Palette.muted),
              ),
          ],
        ),
      ),
      body: entries == null
          ? const SizedBox.shrink()
          : entries.isEmpty
          ? const Center(
              child: Text(
                'Nothing logged on this day.',
                style: TextStyle(color: Palette.muted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EntryCard(
                      entry: entry,
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LogWorkoutScreen(
                            exercise: entry.exercise,
                            day: widget.day,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onEdit});

  final DayEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.exercise.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final set in entry.sets) SetChip(text: formatSetShort(set)),
            ],
          ),
        ],
      ),
    );
  }
}
