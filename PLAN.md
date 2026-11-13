# Gym tracker - plan

Small personal Android app, not on the Play Store: build it and install it on your own
phone. Log exercises as sets of
kg x reps and see, per exercise, a chart that answers one question: am I getting
stronger month over month?

## Scope

In:
- Define exercises (add, rename, delete).
- Log a workout for an exercise: a date and a list of sets, each set = kg + reps.
- Edit or delete a past day.
- Per-exercise progress chart in kg, plus a "vs a month ago" number.
- See when you last trained, overall and per exercise, and what you did that day.
- Export everything to CSV (backup).
- Calendar: a month view marking the days you trained (consistency at a glance).

Out (for now): routines/templates, rest timer, body weight, cloud sync, accounts,
ads, notifications, i18n (UI is English).

## Stack

- Flutter / Dart (3.50+), Android only, package `app.gulolio.gym`, label "Gym".
- Material widgets from the `material_ui` package (Flutter 3.50 deprecates
  `package:flutter/material.dart` in its favour).
- SQLite via `sqflite` (data lives on the phone).
- `intl` for date formatting.
- `share_plus` + `path_provider` for the CSV export.
- Chart drawn by hand with a `CustomPainter`: no chart library; one small chart is
  ~150 lines we fully control.
- Tests: plain `package:test` + `sqflite_common_ffi`, so the logic and DB tests run
  with `dart test` on the desktop (no Flutter engine). Run them in a DST timezone too:
  `TZ=Europe/Paris dart test`.
- Release build signed with the debug key of the machine that builds it (no
  keystore). NOTE: keep updating from the same machine; a build from another machine
  will not install over it, and uninstalling deletes the data (export CSV first).
- Install: `flutter run --release` with the phone connected over USB or wireless adb.

## Look

Dark only, black base with yellow as the action color and purple as the second color.

| Token      | Hex       | Use                                        |
|------------|-----------|--------------------------------------------|
| bg         | `#0B0B0F` | screen background (near black)             |
| surface    | `#16161D` | cards, list tiles                          |
| surfaceHi  | `#20202A` | inputs, pressed state                      |
| line       | `#2C2C38` | dividers, chart grid                       |
| text       | `#F2F2F5` | main text                                  |
| muted      | `#8A8A99` | dates, labels, axis text                   |
| yellow     | `#FFD60A` | FAB, primary buttons, chart, gains         |
| purple     | `#9D4EDD` | selected chips, today ring, add-set border |
| purpleText | `#C49AF5` | purple text (drops badge); `#9D4EDD` is too dark for small text on black |
| onYellow   | `#0B0B0F` | text on yellow                             |

Big numbers for kg/reps (gym use, sweaty thumbs): large touch targets, numeric keyboard.
Material 3 with these colors, default Roboto font.

## Screens

Bottom bar with two tabs: **Exercises** (default) and **Calendar**.

1. **Exercises (home)**
   - Header: "Last workout: Tue 11 Nov (2 days ago)" = the latest day with any set,
     across all exercises. Tap it -> that day's log (every exercise done that day,
     every set), read-only, so you can see what you did.
   - Menu (top right): "Export CSV".
   - List of exercises, the most recently trained first. Each row: name, last day ("3 days ago"), heaviest set of that day
     ("80 kg x 5"), and a month badge: `+5 kg` in yellow, `-2.5 kg` in purple, nothing
     when there is no session a month old yet.
   - Yellow FAB "+" -> dialog to add an exercise (name, unique, case-insensitive).
   - Long-press a row -> rename / delete (delete asks to confirm; removes its sets).
   - Empty state: one line telling you to add your first exercise.

2. **Exercise detail**
   - Chart card on top (see "How stronger is measured").
     - Range toggle: 3M / 6M / 1Y / All.
     - Tap a point -> shows its date and that set ("45 kg x 2").
     - Under the chart: "vs a month ago: +5 kg".
   - History below, newest first, one card per day: date + the sets
     (`1   60 kg x 8`, `2   60 kg x 8`, ...). Tap a day -> edit it.
   - Yellow FAB "Log workout" -> log screen for today.

3. **Log workout**
   - Date at the top (today by default, tap to change).
   - Starts EMPTY: one blank set row, nothing pre-filled.
   - Above the rows, read-only, muted: "Last time: Tue 11 Nov - 30x8, 40x6, 40x4,
     45x2, 40x2" (the previous session of this exercise before the chosen date), so you
     can see what you did without it being typed in for you. Hidden on the first ever
     session.
   - Rows of sets: kg field, reps field, delete button.
   - "+ Add set" copies the previous row's kg and reps, so a 4x8 at 60 kg is: type
     once, tap "+" three times.
   - Save writes the whole day (replaces what that day had). Logging a date that
     already has sets opens those sets for editing instead of adding a duplicate day.
   - kg accepts decimals (2.5 plates, `,` or `.`); 0 kg allowed (bodyweight);
     reps must be >= 1.

4. **Calendar**
   - One month as a grid, weeks start on Monday. Arrows (and swipe) to go to the
     previous / next month; can't go past the current month.
   - A day you trained = filled yellow circle with the number in black. Other days =
     plain muted number. Today = purple ring (also when it is a trained day).
   - Under the title: "9 days this month" (trained days in the shown month), and for
     the current month "this week: 3".
   - Tap a trained day -> that day's view (screen 5), where each exercise can be
     edited and more exercises added for that day.
   - Tap an empty PAST day (or today) -> pick an exercise -> Log workout for that
     day. Future days do nothing. (Logging past days is also possible from Log
     workout itself: tap the date, "Change".)
   - "Trained" = at least one set of any exercise that day. Comes straight from
     `SELECT DISTINCT day FROM sets`; no new table.
   - Drawn by hand (a 7-column grid), no calendar package.

5. **Day view** (read-only)
   - Date as title; every exercise done that day with all its sets in order.
   - Reached from the "Last workout" header and from calendar taps. Each exercise has
     an "Edit" link that opens Log workout for that exercise and day.
   - "Add exercise to this day" button -> pick an exercise -> Log workout for that
     day, so a forgotten exercise can be filled in afterwards.

## How "stronger" is measured

Plot only what was actually lifted. No estimates, no formulas.

- Y axis starts at **0 kg**, so the height of a point is the real weight.
- Points are **joined with a line**.
- **One point per training day: the heaviest set lifted that day.** Flat bench
  `30x8, 40x6, 40x4, 45x2, 40x2` = 1 point at **45 kg**. (Plotting every set was tried
  in the mockup: warm-up sets make the line zigzag every day and hide the trend.)
- Purple fill under the line, fading to the 0 kg axis.
- Tap a point -> date and that set ("Wed 11 Nov - 45 kg x 2"); the reps live there.
  Every set is stored and shown in the history either way.
- **vs a month ago** (the badge): heaviest set of the last session minus the heaviest
  set of the latest session at least 30 days before it.
- X axis is real time (rest weeks show as gaps), month labels along the bottom.
- Flat and incline bench are two separate exercises; each has its own chart.

## Data (SQLite, `gym.db`)

RULE: SQLite is the only storage. No JSON files, no shared_preferences blobs, no
JSON-encoded columns: every exercise and every set is a real row. If settings appear
later (e.g. default chart range), they go in a `settings(key, value)` table in the
same DB. A CSV export, if we add it, is a one-way backup file, never read back as
storage.

```
exercises(id INTEGER PK, name TEXT NOT NULL UNIQUE COLLATE NOCASE, created_at INTEGER)
sets(id INTEGER PK,
     exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
     day TEXT NOT NULL,          -- 'YYYY-MM-DD', local date
     position INTEGER NOT NULL,  -- 1, 2, 3 ... order within the day
     kg REAL NOT NULL, reps INTEGER NOT NULL)
index on sets(exercise_id, day)
```

A "session" is just the sets of one exercise on one day; no separate table. Schema
versioned with `PRAGMA user_version` for later migrations; foreign keys on.

## CSV export

- Home menu -> "Export CSV" -> builds `gym-YYYY-MM-DD.csv` in the app's temp dir and
  opens the Android share sheet (save to Drive / Files / send to Telegram).
- One row per set, oldest first:
  `date,exercise,set,kg,reps` e.g. `2026-11-11,Bench press flat,4,45,2`.
- Names with commas or quotes are quoted per RFC 4180. kg uses `.` as decimal.
- Export only. No import for now (if ever, it would insert rows into SQLite, not
  replace storage).

## Exercise catalog with pictograms (planned, 2026-11-13)

Problem: at the gym you see a machine and don't know its name, in English or Spanish.
So "Add exercise" opens a built-in catalog: each exercise has a small picture, its
English name and its Spanish name. Typing a custom name stays possible.

Pictures: our own pictograms, drawn in code (a figure plus the machine, yellow on a
purple tile). Not photos: the free photo sets found (free-exercise-db) license the
data as public domain but say nothing about the images or where they came from, so
they can't go into a public repo safely. Own drawings: no license question, small,
match the theme, same style for every exercise.

How they are drawn: one painter, each exercise is data (joint positions of a stick
figure + a few equipment lines/circles on a 64x64 grid). No image files, no new
package.

Catalog (first version, about 28; names EN / ES):

| Group     | Exercises |
|-----------|-----------|
| Back      | Lat pulldown / Jalon al pecho; Seated cable row / Remo sentado en polea; Barbell row / Remo con barra; One-arm dumbbell row / Remo con mancuerna; Pull-up / Dominadas; Deadlift / Peso muerto |
| Chest     | Bench press flat / Press de banca plano; Incline bench press / Press de banca inclinado; Dumbbell bench press / Press con mancuernas; Chest fly machine / Aperturas en maquina; Cable crossover / Cruce de poleas; Push-up / Flexiones |
| Legs      | Squat / Sentadilla; Leg press / Prensa de piernas; Leg extension / Extension de cuadriceps; Leg curl / Curl femoral; Calf raise / Elevacion de gemelos; Lunge / Zancadas; Hip thrust / Empuje de cadera |
| Shoulders | Shoulder press / Press militar; Lateral raise / Elevaciones laterales; Face pull / Face pull |
| Arms      | Biceps curl / Curl de biceps; Hammer curl / Curl martillo; Triceps pushdown / Extension de triceps en polea; Dips / Fondos |
| Core      | Plank / Plancha; Crunch / Abdominales |

(Accents shown without marks here; in the app the Spanish names carry them, written
as `\u00f3`-style escapes so the source stays plain ASCII.)

Add exercise screen:
- Search box (matches English or Spanish name), group chips: All, Back, Chest, Legs,
  Shoulders, Arms, Core.
- Grid of cards: pictogram, English name, Spanish name below in grey.
- Already added ones are marked and not added twice.
- At the bottom: "Custom exercise" -> the current name dialog.
- The exercise is added with the English name; it can still be renamed.

Where the pictogram shows: home list rows, exercise screen header, day view.
Custom exercises (no picture) show their first letter on the same purple tile.
Existing exercises: long-press -> "Change picture" picks one from the catalog.

Data: `exercises.catalog_id TEXT NULL` (the catalog key, e.g. `lat_pulldown`);
schema version 2, `ALTER TABLE exercises ADD COLUMN catalog_id TEXT`. The catalog
itself is code, not a table (it ships with the app; the DB keeps only the link).

## Code layout

```
lib/main.dart                 opens the DB, app, bottom bar
lib/store.dart                Store (repo + change counter), reload-on-change mixin
lib/theme.dart                palette tokens + ThemeData
lib/models.dart               Exercise, WorkSet, Session, ExerciseSummary
lib/stats.dart                topSet, chart points, month change (pure, tested)
lib/db.dart                   Repo: the only SQL owner
lib/format.dart               kg formatting (80, 82.5), dates, field parsing
lib/calendar_math.dart        Monday-first month grid, week/month counts
lib/csv_export.dart           rows -> CSV text (pure, tested) + share
lib/widgets/progress_chart.dart
lib/screens/home.dart
lib/screens/exercise.dart
lib/screens/log_workout.dart
lib/screens/day.dart          read-only view of one gym day (all exercises)
lib/screens/calendar.dart     month grid of trained days
test/stats_test.dart
test/db_test.dart
test/csv_export_test.dart
test/format_test.dart
test/calendar_math_test.dart
```

## Steps

1. Scaffold (done).
2. stats.dart + tests (done).
3. db.dart + tests (done).
4. Theme + home screen (done).
5. Log workout screen (done).
6. Exercise screen + chart (done).
7. Day view + "Last workout" header (done).
7b. Calendar tab (month grid logic tested: leap years, Monday start, month lengths).
8. CSV export + test (done).
9. Analyze / tests clean -> run it on a phone and adjust the look.
10. Screenshots of the real app (adb `exec-out screencap -p`) into `docs/screenshots/`
    and into the README.

## Decisions (2026-11-13)

1. Log screen starts empty; the last session is shown read-only above the rows.
2. Chart = heaviest set actually lifted per day, joined by a line, axis from 0 kg,
   purple fill below; no 1RM estimate.
3. CSV export: yes, now.
4. UI in English.
5. Name "Gym", default Flutter icon for now.
6. Calendar of trained days, as its own tab.

## State (2026-11-13)

- Android scaffold (package, label, black splash, default icon, release signed with
  the debug key), `pubspec.yaml`, `analysis_options.yaml`.
- Data layer done: `db.dart` (SQLite repo), `stats.dart`, `format.dart`,
  `calendar_math.dart`, `csv_export.dart`; 37 tests green.
- All screens written (steps 4-8); analyzer clean. Not yet run on a phone.
