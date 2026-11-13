import 'package:material_ui/material_ui.dart';

import '../catalog.dart';
import '../db.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/name_dialog.dart';
import '../widgets/pictogram.dart';

/// Result of the picture picker: the chosen entry, or null for "no picture".
class PictureChoice {
  const PictureChoice(this.entry);

  final CatalogEntry? entry;
}

/// Catalog of exercises with pictograms. In the default mode tapping a card
/// adds that exercise and pops with the new [Exercise]; with [pickPicture]
/// it only pops with a [PictureChoice] (used by "Change picture").
class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key, this.pickPicture = false});

  final bool pickPicture;

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen>
    with ReloadOnChange {
  final _search = TextEditingController();
  MuscleGroup? _group;

  /// Catalog key -> the exercise already added from it.
  Map<String, Exercise> _added = const {};

  @override
  Future<void> reload() async {
    final exercises = await StoreScope.of(context).repo.exercises();
    if (!mounted) return;
    setState(() {
      _added = {
        for (final exercise in exercises)
          if (exercise.catalogId != null) exercise.catalogId!: exercise,
      };
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _tap(CatalogEntry entry) async {
    if (widget.pickPicture) {
      Navigator.of(context).pop(PictureChoice(entry));
      return;
    }
    final existing = _added[entry.id];
    if (existing != null) {
      Navigator.of(context).pop(existing);
      return;
    }
    await _add(entry.nameEn, entry.id);
  }

  Future<void> _custom() async {
    final choice = await askName(
      context,
      title: 'Custom exercise',
      initial: _search.text.trim(),
    );
    if (choice == null) return;
    await _add(choice.name, choice.catalogId);
  }

  Future<void> _add(String name, String? catalogId) async {
    final store = StoreScope.of(context);
    try {
      final exercise = await store.repo.addExercise(
        name,
        catalogId: catalogId,
      );
      store.changed();
      if (mounted) Navigator.of(context).pop(exercise);
    } on DuplicateNameException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = searchCatalog(_search.text, group: _group);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.pickPicture ? 'Choose a picture' : 'Add exercise',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search, English or Spanish',
                prefixIcon: Icon(Icons.search, color: Palette.muted),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              children: [
                _chip('All', null),
                for (final group in MuscleGroup.values) _chip(group.label, group),
              ],
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.pickPicture
                          ? 'No picture matches.'
                          : 'Not in the list. Use "Custom exercise" below.',
                      style: const TextStyle(color: Palette.muted),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 160,
                        ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) => _card(entries[index]),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: OutlinedButton(
            onPressed: widget.pickPicture
                ? () => Navigator.of(context).pop(const PictureChoice(null))
                : _custom,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              foregroundColor: Palette.purpleChipText,
              side: const BorderSide(color: Palette.purple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(
              widget.pickPicture
                  ? 'No picture (show the first letter)'
                  : 'Custom exercise (type a name)',
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, MuscleGroup? group) {
    final on = _group == group;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        onPressed: () => setState(() => _group = group),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: on ? Palette.purpleChip : Colors.transparent,
          foregroundColor: on ? Palette.purpleChipText : Palette.muted,
          side: BorderSide(color: on ? Palette.purple : Palette.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: on ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _card(CatalogEntry entry) {
    final added = !widget.pickPicture && _added.containsKey(entry.id);
    return Panel(
      padding: const EdgeInsets.all(12),
      onTap: () => _tap(entry),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExerciseTile(catalogId: entry.id, name: entry.nameEn, size: 72),
              const SizedBox(height: 8),
              Text(
                entry.nameEn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                entry.nameEs,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Palette.muted),
              ),
            ],
          ),
          if (added)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Palette.yellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Added',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Palette.onYellow,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
