import 'package:material_ui/material_ui.dart';

import '../catalog.dart';
import '../theme.dart';
import 'pictogram.dart';

/// What the name dialog returns: the typed name and, when it is a catalog
/// exercise (picked from the suggestions or typed exactly), its catalog key.
class NameChoice {
  const NameChoice(this.name, this.catalogId);

  final String name;
  final String? catalogId;
}

/// Name dialog with catalog autocomplete. Returns null on cancel.
Future<NameChoice?> askName(
  BuildContext context, {
  required String title,
  String initial = '',
}) => showDialog<NameChoice>(
  context: context,
  builder: (_) => _NameDialog(title: title, initial: initial),
);

/// Owns its controller so it is disposed after the closing animation, not
/// while the dialog is still on screen.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    // A name typed exactly like a catalog entry (English or Spanish) links
    // its pictogram too; the English name is kept as the exercise name.
    final entry = catalogEntryByName(name);
    Navigator.pop(
      context,
      entry == null ? NameChoice(name, null) : NameChoice(entry.nameEn, entry.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 320,
        child: RawAutocomplete<CatalogEntry>(
          textEditingController: _controller,
          focusNode: _focus,
          displayStringForOption: (entry) => entry.nameEn,
          optionsBuilder: (value) {
            if (value.text.trim().isEmpty) return const [];
            return searchCatalog(value.text).take(6);
          },
          onSelected: (entry) => _controller.text = entry.nameEn,
          fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
            controller: controller,
            focusNode: focus,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Lat pulldown or jalon',
            ),
            onSubmitted: (_) => _submit(),
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Palette.surfaceHi,
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300, maxWidth: 320),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shrinkWrap: true,
                  children: [
                    for (final entry in options)
                      ListTile(
                        leading: ExerciseTile(
                          catalogId: entry.id,
                          name: entry.nameEn,
                          size: 40,
                        ),
                        title: Text(entry.nameEn),
                        subtitle: Text(
                          entry.nameEs,
                          style: const TextStyle(color: Palette.muted),
                        ),
                        onTap: () => onSelected(entry),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
