import 'package:gym_tracker/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('ids and names are unique', () {
    final ids = catalog.map((entry) => entry.id).toList();
    expect(ids.toSet().length, ids.length);
    final names = catalog.map((entry) => foldForSearch(entry.nameEn)).toList();
    expect(names.toSet().length, names.length);
  });

  test('every group has entries', () {
    for (final group in MuscleGroup.values) {
      expect(catalog.where((entry) => entry.group == group), isNotEmpty,
          reason: group.label);
    }
  });

  test('every pictogram stays inside the 64 x 64 grid', () {
    bool inside(GridPoint point) =>
        point.$1 >= 0 && point.$1 <= 64 && point.$2 >= 0 && point.$2 <= 64;
    for (final entry in catalog) {
      final pose = entry.pose;
      final points = [
        pose.head,
        for (final line in [...pose.body, ...pose.gear]) ...line,
        for (final ring in [...pose.plates, ...pose.pulleys]) ring.center,
        ...pose.dumbbells,
      ];
      expect(points.every(inside), isTrue, reason: entry.id);
      expect(pose.body, isNotEmpty, reason: entry.id);
      for (final line in [...pose.body, ...pose.gear]) {
        expect(line.length, greaterThanOrEqualTo(2), reason: entry.id);
      }
    }
  });

  test('foldForSearch drops case and accents', () {
    expect(foldForSearch('Jal\u00f3n'), 'jalon');
    expect(foldForSearch('CU\u00c1DRICEPS'.toLowerCase()), 'cuadriceps');
    expect(foldForSearch('B\u00edceps'), 'biceps');
  });

  group('searchCatalog', () {
    List<String> ids(List<CatalogEntry> entries) =>
        [for (final entry in entries) entry.id];

    test('finds by Spanish name without accents', () {
      expect(ids(searchCatalog('jalon')), ['lat_pulldown']);
    });

    test('finds by English words in any order', () {
      expect(ids(searchCatalog('row cable')), ['seated_cable_row']);
    });

    test('empty query lists everything, group filters', () {
      expect(searchCatalog('').length, catalog.length);
      expect(searchCatalog('', group: MuscleGroup.back).length, 6);
      expect(ids(searchCatalog('remo', group: MuscleGroup.back)),
          ['seated_cable_row', 'barbell_row', 'dumbbell_row']);
      expect(searchCatalog('remo', group: MuscleGroup.legs), isEmpty);
    });
  });

  test('lookup by id and by exact name', () {
    expect(catalogEntry('lat_pulldown')!.nameEs, 'Jal\u00f3n al pecho');
    expect(catalogEntry(null), isNull);
    expect(catalogEntry('nope'), isNull);
    expect(catalogEntryByName(' lat PULLDOWN ')!.id, 'lat_pulldown');
    expect(catalogEntryByName('jalon al pecho')!.id, 'lat_pulldown');
    expect(catalogEntryByName('lat'), isNull);
  });
}
