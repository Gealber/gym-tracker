/// Built-in exercises with English and Spanish names and a pictogram.
///
/// Pictograms are data on a 64 x 64 grid, drawn by widgets/pictogram.dart:
/// [Pose.body] polylines are the figure, [Pose.gear] the machine or bench,
/// [Pose.plates] barbell plates, [Pose.dumbbells] dumbbell centers and
/// [Pose.pulleys] small pulley wheels. Spanish names keep their accents as
/// \u escapes so the source stays plain ASCII.
library;

/// A point on the 64 x 64 pictogram grid: (x, y).
typedef GridPoint = (double, double);

/// A circle on the pictogram grid.
class Ring {
  const Ring(this.center, this.radius);

  final GridPoint center;
  final double radius;
}

class Pose {
  const Pose({
    required this.head,
    this.body = const [],
    this.gear = const [],
    this.plates = const [],
    this.dumbbells = const [],
    this.pulleys = const [],
  });

  final GridPoint head;
  final List<List<GridPoint>> body;
  final List<List<GridPoint>> gear;
  final List<Ring> plates;
  final List<GridPoint> dumbbells;
  final List<Ring> pulleys;
}

enum MuscleGroup {
  back('Back'),
  chest('Chest'),
  legs('Legs'),
  shoulders('Shoulders'),
  arms('Arms'),
  core('Core');

  const MuscleGroup(this.label);

  final String label;
}

class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.nameEn,
    required this.nameEs,
    required this.group,
    required this.pose,
  });

  /// Stable key stored in the database; never change an existing one.
  final String id;
  final String nameEn;
  final String nameEs;
  final MuscleGroup group;
  final Pose pose;
}

/// Lower case, accents removed, so "Jalon" matches "Jal\u00f3n".
String foldForSearch(String text) {
  const from = '\u00e1\u00e9\u00ed\u00f3\u00fa\u00fc\u00f1';
  const to = 'aeiouun';
  final lower = text.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    out.write(index >= 0 ? to[index] : char);
  }
  return out.toString();
}

/// Entries whose English or Spanish name contains every word of [query].
List<CatalogEntry> searchCatalog(String query, {MuscleGroup? group}) {
  final words = foldForSearch(query)
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  return [
    for (final entry in catalog)
      if ((group == null || entry.group == group) &&
          words.every((word) =>
              foldForSearch(entry.nameEn).contains(word) ||
              foldForSearch(entry.nameEs).contains(word)))
        entry,
  ];
}

CatalogEntry? catalogEntry(String? id) {
  if (id == null) return null;
  for (final entry in catalog) {
    if (entry.id == id) return entry;
  }
  return null;
}

/// The entry whose English or Spanish name equals [name], ignoring case and
/// accents.
CatalogEntry? catalogEntryByName(String name) {
  final folded = foldForSearch(name.trim());
  for (final entry in catalog) {
    if (foldForSearch(entry.nameEn) == folded ||
        foldForSearch(entry.nameEs) == folded) {
      return entry;
    }
  }
  return null;
}

// Shared pieces.
const _floor = <GridPoint>[(4, 60), (60, 60)];
const _seatFront = <GridPoint>[(20, 45), (44, 45)];
const _seatPost = <GridPoint>[(32, 45), (32, 60)];
const _seatedLegsFront = <List<GridPoint>>[
  [(28, 43), (21, 47), (21, 58)],
  [(36, 43), (43, 47), (43, 58)],
];
const _standingLegsFront = <List<GridPoint>>[
  [(32, 44), (27, 60)],
  [(32, 44), (37, 60)],
];

const catalog = <CatalogEntry>[
  // Back.
  CatalogEntry(
    id: 'lat_pulldown',
    nameEn: 'Lat pulldown',
    nameEs: 'Jal\u00f3n al pecho',
    group: MuscleGroup.back,
    pose: Pose(
      head: (32, 20),
      gear: [
        [(32, 2), (32, 9)],
        [(9, 10), (55, 10)],
        _seatFront,
        _seatPost,
      ],
      body: [
        [(14, 10), (19, 20), (26, 27), (38, 27), (45, 20), (50, 10)],
        [(32, 27), (32, 43)],
        ..._seatedLegsFront,
      ],
    ),
  ),
  CatalogEntry(
    id: 'seated_cable_row',
    nameEn: 'Seated cable row',
    nameEs: 'Remo sentado en polea',
    group: MuscleGroup.back,
    pose: Pose(
      head: (23, 18),
      gear: [
        [(6, 48), (30, 48)],
        [(51, 36), (51, 54)],
        [(33, 33), (56, 49)],
      ],
      pulleys: [Ring((57, 50), 3)],
      body: [
        [(20, 45), (22, 26)],
        [(20, 45), (35, 38), (49, 44)],
        [(22, 28), (13, 33), (31, 33)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'barbell_row',
    nameEn: 'Barbell row',
    nameEs: 'Remo con barra',
    group: MuscleGroup.back,
    pose: Pose(
      head: (13, 21),
      gear: [_floor],
      plates: [Ring((30, 41), 7)],
      body: [
        [(18, 24), (36, 34)],
        [(36, 34), (40, 46), (36, 58)],
        [(22, 26), (22, 36), (30, 39)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'dumbbell_row',
    nameEn: 'One-arm dumbbell row',
    nameEs: 'Remo con mancuerna',
    group: MuscleGroup.back,
    pose: Pose(
      head: (11, 23),
      gear: [
        [(8, 40), (36, 40)],
        [(12, 40), (12, 56)],
        [(32, 40), (32, 56)],
      ],
      dumbbells: [(28, 30)],
      body: [
        [(16, 26), (38, 28)],
        [(18, 27), (16, 38)],
        [(38, 28), (30, 38), (30, 40)],
        [(38, 28), (46, 42), (48, 58)],
        [(20, 27), (26, 36), (28, 31)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'pull_up',
    nameEn: 'Pull-up',
    nameEs: 'Dominadas',
    group: MuscleGroup.back,
    pose: Pose(
      head: (32, 16),
      gear: [
        [(8, 8), (56, 8)],
      ],
      body: [
        [(16, 8), (19, 20), (27, 25), (37, 25), (45, 20), (48, 8)],
        [(32, 25), (32, 43)],
        [(29, 43), (27, 52), (30, 60)],
        [(35, 43), (37, 52), (34, 60)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'deadlift',
    nameEn: 'Deadlift',
    nameEs: 'Peso muerto',
    group: MuscleGroup.back,
    pose: Pose(
      head: (28, 12),
      gear: [_floor],
      plates: [Ring((33, 51), 8)],
      body: [
        [(30, 18), (36, 36)],
        [(36, 36), (30, 46), (34, 58)],
        [(31, 22), (33, 44)],
      ],
    ),
  ),

  // Chest.
  CatalogEntry(
    id: 'bench_press',
    nameEn: 'Bench press flat',
    nameEs: 'Press de banca plano',
    group: MuscleGroup.chest,
    pose: Pose(
      head: (9, 38),
      gear: [
        [(6, 44), (46, 44)],
        [(12, 44), (12, 58)],
        [(42, 44), (42, 58)],
      ],
      plates: [Ring((18, 15), 6)],
      body: [
        [(14, 40), (38, 40)],
        [(38, 40), (48, 32), (52, 50)],
        [(18, 40), (18, 21)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'incline_bench_press',
    nameEn: 'Incline bench press',
    nameEs: 'Press de banca inclinado',
    group: MuscleGroup.chest,
    pose: Pose(
      head: (16, 26),
      gear: [
        [(12, 30), (38, 51)],
        [(38, 51), (52, 51)],
        [(42, 51), (42, 60)],
      ],
      plates: [Ring((25, 10), 6)],
      body: [
        [(21, 32), (40, 46)],
        [(40, 46), (52, 42), (56, 58)],
        [(23, 33), (25, 16)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'incline_dumbbell_press',
    nameEn: 'Incline dumbbell press',
    nameEs: 'Press inclinado con mancuernas',
    group: MuscleGroup.chest,
    pose: Pose(
      head: (16, 26),
      gear: [
        [(12, 30), (38, 51)],
        [(38, 51), (52, 51)],
        [(42, 51), (42, 60)],
      ],
      dumbbells: [(25, 13)],
      body: [
        [(21, 32), (40, 46)],
        [(40, 46), (52, 42), (56, 58)],
        [(23, 33), (25, 16)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'dumbbell_bench_press',
    nameEn: 'Dumbbell bench press',
    nameEs: 'Press con mancuernas',
    group: MuscleGroup.chest,
    pose: Pose(
      head: (9, 38),
      gear: [
        [(6, 44), (46, 44)],
        [(12, 44), (12, 58)],
        [(42, 44), (42, 58)],
      ],
      dumbbells: [(18, 19)],
      body: [
        [(14, 40), (38, 40)],
        [(38, 40), (48, 32), (52, 50)],
        [(18, 40), (18, 22)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'chest_fly_machine',
    nameEn: 'Chest fly machine',
    nameEs: 'Aperturas en m\u00e1quina',
    group: MuscleGroup.chest,
    pose: Pose(
      head: (32, 20),
      gear: [
        [(9, 14), (9, 34)],
        [(55, 14), (55, 34)],
        _seatFront,
        _seatPost,
      ],
      body: [
        [(11, 24), (19, 26), (26, 27), (38, 27), (45, 26), (53, 24)],
        [(32, 27), (32, 43)],
        ..._seatedLegsFront,
      ],
    ),
  ),
  CatalogEntry(
    id: 'cable_crossover',
    nameEn: 'Cable crossover',
    nameEs: 'Cruce de poleas',
    group: MuscleGroup.chest,
    pose: Pose(
      head: (32, 16),
      gear: [
        [(6, 6), (29, 41)],
        [(58, 6), (35, 41)],
      ],
      pulleys: [Ring((5, 5), 3), Ring((59, 5), 3)],
      body: [
        [(31, 42), (22, 34), (26, 24), (38, 24), (42, 34), (33, 42)],
        [(32, 24), (32, 44)],
        ..._standingLegsFront,
      ],
    ),
  ),
  CatalogEntry(
    id: 'push_up',
    nameEn: 'Push-up',
    nameEs: 'Flexiones',
    group: MuscleGroup.chest,
    pose: Pose(
      head: (11, 30),
      gear: [_floor],
      body: [
        [(16, 34), (56, 58)],
        [(18, 35), (18, 58)],
      ],
    ),
  ),

  // Legs.
  CatalogEntry(
    id: 'squat',
    nameEn: 'Squat',
    nameEs: 'Sentadilla',
    group: MuscleGroup.legs,
    pose: Pose(
      head: (36, 14),
      gear: [_floor],
      plates: [Ring((30, 21), 7)],
      body: [
        [(22, 40), (33, 22)],
        [(22, 40), (38, 44), (34, 58)],
        [(33, 24), (38, 30), (34, 21)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'leg_press',
    nameEn: 'Leg press',
    nameEs: 'Prensa de piernas',
    group: MuscleGroup.legs,
    pose: Pose(
      head: (9, 30),
      gear: [
        [(5, 32), (18, 53)],
        [(18, 53), (32, 53)],
        [(45, 13), (59, 30)],
      ],
      body: [
        [(12, 36), (24, 50)],
        [(24, 50), (40, 33), (51, 22)],
        [(14, 40), (24, 46)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'leg_extension',
    nameEn: 'Leg extension',
    nameEs: 'Extensi\u00f3n de cu\u00e1driceps',
    group: MuscleGroup.legs,
    pose: Pose(
      head: (17, 14),
      gear: [
        [(10, 43), (34, 43)],
        [(10, 43), (8, 16)],
        [(22, 43), (22, 60)],
      ],
      pulleys: [Ring((53, 34), 4)],
      body: [
        [(16, 40), (16, 21)],
        [(16, 40), (34, 40), (50, 34)],
        [(16, 23), (22, 33), (26, 40)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'leg_curl',
    nameEn: 'Leg curl',
    nameEs: 'Curl femoral',
    group: MuscleGroup.legs,
    pose: Pose(
      head: (7, 32),
      gear: [
        [(4, 40), (46, 40)],
        [(10, 40), (10, 56)],
        [(40, 40), (40, 56)],
      ],
      pulleys: [Ring((43, 15), 4)],
      body: [
        [(12, 36), (34, 36)],
        [(34, 36), (48, 36), (44, 19)],
        [(14, 36), (12, 44)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'calf_raise',
    nameEn: 'Calf raise',
    nameEs: 'Elevaci\u00f3n de gemelos',
    group: MuscleGroup.legs,
    pose: Pose(
      head: (32, 12),
      gear: [
        [(24, 55), (48, 55)],
        [(24, 55), (24, 62)],
      ],
      dumbbells: [(28, 38)],
      body: [
        [(32, 19), (32, 38)],
        [(32, 38), (33, 48), (36, 54)],
        [(32, 21), (28, 30), (28, 36)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'lunge',
    nameEn: 'Lunge',
    nameEs: 'Zancadas',
    group: MuscleGroup.legs,
    pose: Pose(
      head: (30, 12),
      gear: [_floor],
      dumbbells: [(30, 38)],
      body: [
        [(30, 19), (30, 37)],
        [(30, 37), (42, 45), (44, 58)],
        [(30, 37), (22, 52), (10, 56)],
        [(30, 21), (31, 35)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'hip_thrust',
    nameEn: 'Hip thrust',
    nameEs: 'Empuje de cadera',
    group: MuscleGroup.legs,
    pose: Pose(
      head: (9, 29),
      gear: [
        [(4, 36), (18, 36)],
        [(10, 36), (10, 58)],
        _floor,
      ],
      plates: [Ring((36, 24), 6)],
      body: [
        [(14, 33), (36, 30)],
        [(36, 30), (47, 39), (47, 58)],
      ],
    ),
  ),

  // Shoulders.
  CatalogEntry(
    id: 'shoulder_press',
    nameEn: 'Shoulder press',
    nameEs: 'Press militar',
    group: MuscleGroup.shoulders,
    pose: Pose(
      head: (32, 20),
      gear: [_seatFront, _seatPost],
      dumbbells: [(16, 8), (48, 8)],
      body: [
        [(16, 10), (18, 22), (26, 27), (38, 27), (46, 22), (48, 10)],
        [(32, 27), (32, 43)],
        ..._seatedLegsFront,
      ],
    ),
  ),
  CatalogEntry(
    id: 'lateral_raise',
    nameEn: 'Lateral raise',
    nameEs: 'Elevaciones laterales',
    group: MuscleGroup.shoulders,
    pose: Pose(
      head: (32, 17),
      gear: [_floor],
      dumbbells: [(8, 24), (56, 24)],
      body: [
        [(11, 24), (26, 26), (38, 26), (53, 24)],
        [(32, 26), (32, 44)],
        ..._standingLegsFront,
      ],
    ),
  ),
  CatalogEntry(
    id: 'dumbbell_shrug',
    nameEn: 'Dumbbell shrug',
    nameEs: 'Encogimientos de trapecio',
    group: MuscleGroup.shoulders,
    pose: Pose(
      head: (32, 13),
      gear: [
        // Arrows over the shoulders: the shoulders go up.
        [(20, 15), (20, 6)],
        [(17, 9), (20, 6), (23, 9)],
        [(44, 15), (44, 6)],
        [(41, 9), (44, 6), (47, 9)],
        _floor,
      ],
      dumbbells: [(19, 43), (45, 43)],
      body: [
        [(19, 41), (21, 23), (26, 19), (38, 19), (43, 23), (45, 41)],
        [(32, 19), (32, 44)],
        ..._standingLegsFront,
      ],
    ),
  ),
  CatalogEntry(
    id: 'face_pull',
    nameEn: 'Face pull',
    nameEs: 'Face pull',
    group: MuscleGroup.shoulders,
    pose: Pose(
      head: (29, 15),
      gear: [
        [(58, 4), (58, 60)],
        [(56, 14), (38, 18)],
      ],
      pulleys: [Ring((58, 14), 3)],
      body: [
        [(28, 22), (28, 42)],
        [(28, 42), (24, 60)],
        [(28, 42), (34, 60)],
        [(28, 24), (20, 20), (37, 18)],
      ],
    ),
  ),

  // Arms.
  CatalogEntry(
    id: 'biceps_curl',
    nameEn: 'Biceps curl',
    nameEs: 'Curl de b\u00edceps',
    group: MuscleGroup.arms,
    pose: Pose(
      head: (32, 11),
      gear: [_floor],
      dumbbells: [(42, 21)],
      body: [
        [(32, 18), (32, 40)],
        [(32, 40), (29, 60)],
        [(32, 40), (36, 60)],
        [(32, 20), (32, 31), (40, 23)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'hammer_curl',
    nameEn: 'Hammer curl',
    nameEs: 'Curl martillo',
    group: MuscleGroup.arms,
    pose: Pose(
      head: (32, 16),
      gear: [_floor],
      dumbbells: [(21, 26), (43, 26)],
      body: [
        [(22, 28), (23, 37), (26, 24), (38, 24), (41, 37), (42, 28)],
        [(32, 24), (32, 44)],
        ..._standingLegsFront,
      ],
    ),
  ),
  CatalogEntry(
    id: 'triceps_pushdown',
    nameEn: 'Triceps pushdown',
    nameEs: 'Extensi\u00f3n de tr\u00edceps en polea',
    group: MuscleGroup.arms,
    pose: Pose(
      head: (30, 13),
      gear: [
        [(54, 4), (54, 60)],
        [(52, 9), (41, 38)],
      ],
      pulleys: [Ring((54, 8), 3)],
      body: [
        [(30, 20), (30, 42)],
        [(30, 42), (26, 60)],
        [(30, 42), (34, 60)],
        [(30, 22), (30, 34), (40, 40)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'dips',
    nameEn: 'Dips',
    nameEs: 'Fondos',
    group: MuscleGroup.arms,
    pose: Pose(
      head: (32, 14),
      gear: [
        [(6, 34), (18, 34)],
        [(46, 34), (58, 34)],
        [(10, 34), (10, 60)],
        [(54, 34), (54, 60)],
      ],
      body: [
        [(14, 34), (17, 25), (26, 22), (38, 22), (47, 25), (50, 34)],
        [(32, 22), (32, 42)],
        [(32, 42), (30, 52), (34, 57)],
      ],
    ),
  ),

  // Core.
  CatalogEntry(
    id: 'plank',
    nameEn: 'Plank',
    nameEs: 'Plancha',
    group: MuscleGroup.core,
    pose: Pose(
      head: (9, 38),
      gear: [_floor],
      body: [
        [(14, 42), (56, 54)],
        [(16, 43), (16, 56), (26, 56)],
      ],
    ),
  ),
  CatalogEntry(
    id: 'crunch',
    nameEn: 'Crunch',
    nameEs: 'Abdominales',
    group: MuscleGroup.core,
    pose: Pose(
      head: (11, 42),
      gear: [_floor],
      body: [
        [(16, 47), (34, 56)],
        [(34, 56), (44, 40), (54, 56)],
        [(17, 47), (12, 37)],
      ],
    ),
  ),
];
