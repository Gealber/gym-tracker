import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'screens/calendar.dart';
import 'screens/home.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final repo = await Repo.open(
    databaseFactory,
    path.join(await getDatabasesPath(), 'gym.db'),
  );
  runApp(GymApp(store: Store(repo)));
}

class GymApp extends StatelessWidget {
  const GymApp({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Gym',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Shell(),
      ),
    );
  }
}

/// Bottom bar with the two tabs.
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [HomeTab(), CalendarTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Exercises',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }
}
