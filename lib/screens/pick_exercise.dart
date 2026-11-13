import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/pictogram.dart';
import 'add_exercise.dart';
import 'log_workout.dart';

/// Asks which exercise to log on [day] (your exercises, or a new one from the
/// catalog) and opens Log workout for it.
Future<void> logExerciseOnDay(BuildContext context, DateTime day) async {
  final navigator = Navigator.of(context);
  final exercises = await StoreScope.of(context).repo.exercises();
  if (!context.mounted) return;
  final picked = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _PickSheet(day: day, exercises: exercises),
  );
  Exercise? exercise;
  if (picked is Exercise) {
    exercise = picked;
  } else if (picked == _newExercise) {
    exercise = await navigator.push<Exercise>(
      MaterialPageRoute(builder: (_) => const AddExerciseScreen()),
    );
  }
  if (exercise == null) return;
  await navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => LogWorkoutScreen(exercise: exercise!, day: day),
    ),
  );
}

const _newExercise = 'new';

class _PickSheet extends StatelessWidget {
  const _PickSheet({required this.day, required this.exercises});

  final DateTime day;
  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Log on ${formatDay(day)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final exercise in exercises)
                    ListTile(
                      leading: ExerciseTile(
                        catalogId: exercise.catalogId,
                        name: exercise.name,
                        size: 40,
                      ),
                      title: Text(exercise.name),
                      onTap: () => Navigator.pop(context, exercise),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Palette.yellow),
              title: const Text(
                'New exercise',
                style: TextStyle(color: Palette.yellow),
              ),
              onTap: () => Navigator.pop(context, _newExercise),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
