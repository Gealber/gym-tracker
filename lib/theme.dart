import 'package:material_ui/material_ui.dart';

/// The palette. Dark only.
abstract final class Palette {
  static const bg = Color(0xFF0B0B0F);
  static const surface = Color(0xFF16161D);
  static const surfaceHi = Color(0xFF20202A);
  static const nav = Color(0xFF121218);
  static const line = Color(0xFF2C2C38);
  static const text = Color(0xFFF2F2F5);
  static const muted = Color(0xFF8A8A99);
  static const faint = Color(0xFF4A4A57);
  static const yellow = Color(0xFFFFD60A);
  static const yellowSoft = Color(0xFF2B2508);
  static const purple = Color(0xFF9D4EDD);
  static const purpleText = Color(0xFFC49AF5);
  static const purpleSoft = Color(0xFF231733);
  static const purpleChip = Color(0xFF2A1840);
  static const purpleChipText = Color(0xFFD5B4FA);
  static const onYellow = bg;
  static const danger = Color(0xFFFF6B6B);
}

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: Palette.yellow,
    onPrimary: Palette.onYellow,
    secondary: Palette.purple,
    onSecondary: Colors.white,
    surface: Palette.bg,
    onSurface: Palette.text,
    surfaceContainerHighest: Palette.surfaceHi,
    surfaceContainerHigh: Palette.surface,
    surfaceContainer: Palette.surface,
    surfaceContainerLow: Palette.surface,
    outline: Palette.line,
    outlineVariant: Palette.line,
    error: Palette.danger,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    brightness: Brightness.dark,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.bg,
      foregroundColor: Palette.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Palette.yellow,
      foregroundColor: Palette.onYellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.nav,
      indicatorColor: Palette.yellowSoft,
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Palette.yellow
              : Palette.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? Palette.yellow
              : Palette.muted,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.surfaceHi,
      hintStyle: const TextStyle(color: Palette.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.yellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.danger, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Palette.danger, width: 2),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Palette.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.surface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Palette.surfaceHi,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Palette.surfaceHi,
      contentTextStyle: TextStyle(color: Palette.text),
      behavior: SnackBarBehavior.floating,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Palette.yellow),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.yellow,
        foregroundColor: Palette.onYellow,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}

/// A rounded card on the surface color.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// "+5 kg" on yellow, "-2.5 kg" on purple.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({super.key, required this.text, required this.up});

  final String text;
  final bool up;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: up ? Palette.yellowSoft : Palette.purpleSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: up ? Palette.yellow : Palette.purpleText,
        ),
      ),
    );
  }
}

/// Small rounded chip with one set, e.g. "45 x 2".
class SetChip extends StatelessWidget {
  const SetChip({super.key, required this.text, this.highlight = false});

  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? Palette.yellowSoft : Palette.surfaceHi,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: highlight ? Palette.yellow : Palette.text,
          fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// Grey upper-case section label, "EXERCISES".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Palette.muted,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
