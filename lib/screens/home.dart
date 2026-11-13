import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../csv_export.dart';
import '../db.dart';
import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/name_dialog.dart';
import '../widgets/pictogram.dart';
import 'add_exercise.dart';
import 'day.dart';
import 'exercise.dart';

/// Tab 1: the list of exercises with the last workout on top.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with ReloadOnChange {
  List<ExerciseSummary>? _items;
  DateTime? _lastDay;

  @override
  Future<void> reload() async {
    final repo = StoreScope.of(context).repo;
    final items = await repo.summaries();
    final last = await repo.lastWorkoutDay();
    if (!mounted) return;
    setState(() {
      _items = items;
      _lastDay = last;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gym',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menu',
            onSelected: (choice) {
              if (choice == 'export') _export();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export CSV')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add exercise',
        onPressed: _addExercise,
        child: const Icon(Icons.add, size: 28),
      ),
      body: items == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (_lastDay != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _LastWorkoutCard(day: _lastDay!, today: today),
                  ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 48, 24, 0),
                    child: Text(
                      'No exercises yet. Tap + to add your first one, '
                      'e.g. "Bench press flat".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Palette.muted, fontSize: 16),
                    ),
                  )
                else ...[
                  const SectionLabel('Exercises'),
                  for (final summary in items)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _ExerciseRow(
                        summary: summary,
                        today: today,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ExerciseScreen(exercise: summary.exercise),
                          ),
                        ),
                        onLongPress: () => _exerciseMenu(summary.exercise),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Future<void> _addExercise() => Navigator.of(context).push<Exercise>(
    MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
  );

  Future<void> _exerciseMenu(Exercise exercise) async {
    final store = StoreScope.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(sheetContext, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Change picture'),
              onTap: () => Navigator.pop(sheetContext, 'picture'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Palette.danger),
              title: const Text(
                'Delete',
                style: TextStyle(color: Palette.danger),
              ),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'rename') {
      final choice = await askName(
        context,
        title: 'Rename exercise',
        initial: exercise.name,
      );
      if (choice == null) return;
      try {
        await store.repo.renameExercise(exercise.id, choice.name);
        // Renaming to a catalog name brings its picture; a custom name keeps
        // whatever picture the exercise had.
        if (choice.catalogId != null) {
          await store.repo.setCatalogId(exercise.id, choice.catalogId);
        }
        store.changed();
      } on DuplicateNameException catch (error) {
        _snack(error.toString());
      }
    } else if (action == 'picture') {
      final picked = await Navigator.of(context).push<PictureChoice>(
        MaterialPageRoute(
          builder: (_) => const AddExerciseScreen(pickPicture: true),
        ),
      );
      if (picked == null) return;
      await store.repo.setCatalogId(exercise.id, picked.entry?.id);
      store.changed();
    } else if (action == 'delete') {
      final ok = await confirm(
        context,
        title: 'Delete "${exercise.name}"?',
        body: 'All its logged sets are deleted too. This cannot be undone.',
        action: 'Delete',
      );
      if (!ok) return;
      await store.repo.deleteExercise(exercise.id);
      store.changed();
    }
  }

  Future<void> _export() async {
    final repo = StoreScope.of(context).repo;
    final rows = await repo.allSets();
    if (rows.isEmpty) {
      _snack('Nothing logged yet.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File(path.join(dir.path, csvFileName(DateTime.now())));
    await file.writeAsString(toCsv(rows));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Gym export',
      ),
    );
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _LastWorkoutCard extends StatelessWidget {
  const _LastWorkoutCard({required this.day, required this.today});

  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => DayScreen(day: day))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Palette.yellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: Palette.onYellow),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last workout',
                  style: TextStyle(fontSize: 13, color: Palette.muted),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatDay(day),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: ' - ${daysAgo(day, today)}',
                        style: const TextStyle(
                          fontSize: 17,
                          color: Palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Palette.muted),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.summary,
    required this.today,
    required this.onTap,
    required this.onLongPress,
  });

  final ExerciseSummary summary;
  final DateTime today;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final change = summary.monthChangeKg;
    return Panel(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          ExerciseTile(
            catalogId: summary.exercise.catalogId,
            name: summary.exercise.name,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.exercise.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (summary.lastDay == null)
                  const Text(
                    'Not logged yet',
                    style: TextStyle(fontSize: 14, color: Palette.muted),
                  )
                else
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${daysAgo(summary.lastDay!, today)} - ',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Palette.muted,
                          ),
                        ),
                        TextSpan(
                          text: formatSet(summary.lastTop!),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Palette.text,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (change != null && change != 0)
            ChangeBadge(text: formatChange(change), up: change > 0)
          else if (summary.lastDay != null && change == null)
            const Text(
              'new',
              style: TextStyle(fontSize: 13, color: Palette.muted),
            ),
        ],
      ),
    );
  }
}

/// Yes/no dialog. Returns true only when [action] was tapped.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body, style: const TextStyle(color: Palette.muted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: Palette.danger),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}
