import 'package:flutter/widgets.dart';

import 'db.dart';

/// The open database plus a change counter. Screens read through [repo] and
/// listen to [changes] to reload after any write, wherever it happened.
class Store {
  Store(this.repo);

  final Repo repo;
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Call after every write.
  void changed() => changes.value++;
}

/// Makes the [Store] reachable from any widget below it.
class StoreScope extends InheritedWidget {
  const StoreScope({super.key, required this.store, required super.child});

  final Store store;

  static Store of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.store;

  @override
  bool updateShouldNotify(StoreScope oldWidget) => store != oldWidget.store;
}

/// Mixin for screen states that load data and reload when the store changes.
mixin ReloadOnChange<T extends StatefulWidget> on State<T> {
  Store? _store;

  /// Load (or reload) whatever the screen shows.
  Future<void> reload();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = StoreScope.of(context);
    if (!identical(store, _store)) {
      _store?.changes.removeListener(_onChange);
      _store = store;
      store.changes.addListener(_onChange);
      reload();
    }
  }

  void _onChange() {
    if (mounted) reload();
  }

  @override
  void dispose() {
    _store?.changes.removeListener(_onChange);
    super.dispose();
  }
}
