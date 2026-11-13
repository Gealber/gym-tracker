import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'home.dart' show confirm;

/// Enter the sets of one exercise for one day. Starts empty for a new day,
/// with the previous session shown read-only above; opens the stored sets
/// when the day already has some.
class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({
    super.key,
    required this.exercise,
    required this.day,
  });

  final Exercise exercise;
  final DateTime day;

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _Row {
  _Row({String kg = '', String reps = ''})
    : kg = TextEditingController(text: kg),
      reps = TextEditingController(text: reps);

  final TextEditingController kg;
  final TextEditingController reps;
  final kgFocus = FocusNode();
  String? kgError;
  String? repsError;

  bool get isBlank => kg.text.trim().isEmpty && reps.text.trim().isEmpty;

  void dispose() {
    kg.dispose();
    reps.dispose();
    kgFocus.dispose();
  }
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  late DateTime _day = dateOnly(widget.day);
  final List<_Row> _rows = [];
  Session? _previous;
  bool _dayHasSets = false;
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _rows.isEmpty) _load(keepTyped: false);
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Loads the chosen day. When it already has sets they replace the rows;
  /// otherwise the rows typed so far are kept ([keepTyped]) or reset to one
  /// empty row.
  Future<void> _load({required bool keepTyped}) async {
    final repo = StoreScope.of(context).repo;
    final existing = await repo.session(widget.exercise.id, _day);
    final previous = await repo.previousSession(widget.exercise.id, _day);
    if (!mounted) return;
    setState(() {
      _previous = previous;
      _dayHasSets = existing != null;
      if (existing != null) {
        _replaceRows([
          for (final set in existing.sets)
            _Row(kg: formatKg(set.kg), reps: set.reps.toString()),
        ]);
      } else if (!keepTyped || _rows.isEmpty) {
        _replaceRows([_Row()]);
      }
      _loading = false;
    });
  }

  void _replaceRows(List<_Row> rows) {
    for (final row in _rows) {
      row.dispose();
    }
    _rows
      ..clear()
      ..addAll(rows);
  }

  Future<void> _pickDay() async {
    final today = dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null || dateOnly(picked) == _day) return;
    setState(() => _day = dateOnly(picked));
    await _load(keepTyped: true);
  }

  void _addRow() {
    final last = _rows.isEmpty ? null : _rows.last;
    final row = _Row(kg: last?.kg.text ?? '', reps: last?.reps.text ?? '');
    setState(() => _rows.add(row));
    if (row.kg.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => row.kgFocus.requestFocus(),
      );
    }
  }

  void _removeRow(int i) {
    setState(() {
      _rows.removeAt(i).dispose();
      if (_rows.isEmpty) _rows.add(_Row());
    });
  }

  Future<void> _save() async {
    final store = StoreScope.of(context);
    final sets = <WorkSet>[];
    var valid = true;
    setState(() {
      for (final row in _rows) {
        row.kgError = null;
        row.repsError = null;
        if (row.isBlank) continue;
        final kg = parseKg(row.kg.text);
        final reps = parseReps(row.reps.text);
        if (kg == null) row.kgError = 'kg?';
        if (reps == null) row.repsError = 'reps?';
        if (kg == null || reps == null) {
          valid = false;
        } else {
          sets.add(WorkSet(kg: kg, reps: reps));
        }
      }
    });
    if (!valid) return;
    if (sets.isEmpty) {
      if (!_dayHasSets) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add at least one set.')));
        return;
      }
      final ok = await confirm(
        context,
        title: 'Delete this day?',
        body:
            'All sets are empty, so saving removes ${formatDay(_day)} '
            'for ${widget.exercise.name}.',
        action: 'Delete',
      );
      if (!ok) return;
    }
    await store.repo.saveDay(widget.exercise.id, _day, sets);
    store.changed();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteDay() async {
    final store = StoreScope.of(context);
    final ok = await confirm(
      context,
      title: 'Delete this day?',
      body:
          'Removes every set of ${widget.exercise.name} on '
          '${formatDay(_day)}.',
      action: 'Delete',
    );
    if (!ok) return;
    await store.repo.saveDay(widget.exercise.id, _day, const []);
    store.changed();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayHasSets ? 'Edit workout' : 'Log workout',
              style: const TextStyle(fontSize: 13, color: Palette.muted),
            ),
            Text(
              widget.exercise.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          if (_dayHasSets)
            IconButton(
              tooltip: 'Delete this day',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteDay,
            ),
        ],
      ),
      body: _loading
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _dateButton(today),
                if (_previous != null) ...[
                  const SizedBox(height: 12),
                  _previousCard(_previous!),
                ],
                const SizedBox(height: 20),
                const _RowLayout(
                  number: Text('Set', style: _headStyle),
                  kg: Text('kg', style: _headStyle),
                  reps: Text('Reps', style: _headStyle),
                  action: SizedBox.shrink(),
                ),
                const SizedBox(height: 6),
                for (var i = 0; i < _rows.length; i++) ...[
                  _setRow(i),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: Text(
                    _rows.isNotEmpty && !_rows.last.isBlank
                        ? 'Add set (copies set ${_rows.length})'
                        : 'Add set',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: Palette.purpleChipText,
                    side: const BorderSide(color: Palette.purple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _loading ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
            ),
            child: const Text('Save workout'),
          ),
        ),
      ),
    );
  }

  static const _headStyle = TextStyle(fontSize: 13, color: Palette.muted);

  Widget _dateButton(DateTime today) {
    final isToday = _day == today;
    return Material(
      color: Palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _pickDay,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Palette.yellow),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatDay(_day),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isToday)
                        const TextSpan(
                          text: ' (today)',
                          style: TextStyle(fontSize: 16, color: Palette.muted),
                        ),
                    ],
                  ),
                ),
              ),
              const Text(
                'Change',
                style: TextStyle(fontSize: 14, color: Palette.yellow),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previousCard(Session prev) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF120E1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3E2A5A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last time - ${formatDay(prev.day)}',
            style: const TextStyle(fontSize: 13, color: Color(0xFFB9A5D6)),
          ),
          const SizedBox(height: 6),
          Text(
            prev.sets.map(formatSetShort).join('   '),
            style: const TextStyle(fontSize: 15, color: Color(0xFFC9C9D3)),
          ),
        ],
      ),
    );
  }

  Widget _setRow(int i) {
    final row = _rows[i];
    final isLast = i == _rows.length - 1;
    return _RowLayout(
      number: Text(
        '${i + 1}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isLast ? Palette.yellow : Palette.muted,
        ),
      ),
      kg: _field(
        controller: row.kg,
        focus: row.kgFocus,
        hint: 'kg',
        error: row.kgError,
        keyboard: const TextInputType.numberWithOptions(decimal: true),
        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      ),
      reps: _field(
        controller: row.reps,
        hint: 'reps',
        error: row.repsError,
        keyboard: TextInputType.number,
        formatters: [FilteringTextInputFormatter.digitsOnly],
        action: isLast ? TextInputAction.done : TextInputAction.next,
      ),
      action: IconButton(
        tooltip: 'Delete set ${i + 1}',
        icon: const Icon(Icons.close, color: Palette.muted),
        onPressed: () => _removeRow(i),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    FocusNode? focus,
    required String hint,
    required String? error,
    required TextInputType keyboard,
    required List<TextInputFormatter> formatters,
    TextInputAction action = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      focusNode: focus,
      keyboardType: keyboard,
      inputFormatters: formatters,
      textInputAction: action,
      textAlign: TextAlign.center,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        errorText: error,
        errorStyle: const TextStyle(height: 0.8),
      ),
    );
  }
}

/// Set number | kg | reps | delete, the same columns for header and rows.
class _RowLayout extends StatelessWidget {
  const _RowLayout({
    required this.number,
    required this.kg,
    required this.reps,
    required this.action,
  });

  final Widget number;
  final Widget kg;
  final Widget reps;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 36, child: Center(child: number)),
        const SizedBox(width: 10),
        Expanded(child: kg),
        const SizedBox(width: 10),
        Expanded(child: reps),
        SizedBox(width: 48, child: Center(child: action)),
      ],
    );
  }
}
