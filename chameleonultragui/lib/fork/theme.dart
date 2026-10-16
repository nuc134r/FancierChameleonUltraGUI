import 'package:chameleonultragui/helpers/font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// The fork's look: near-black surfaces with a faint olive bias, PCB gold accent (taken from the
// Chameleon's own board), tight corners, and monospace reserved for data (UIDs, keys, hex).

const pcbGold = Color(0xFFD9A93A);

// Font bundled by upstream (pubspec.yaml) and used for all data values.
const monoFamily = 'RobotoMono';

TextStyle monoStyle(BuildContext context, {double? size, Color? color}) {
  return TextStyle(
    fontFamily: monoFamily,
    fontSize: size ?? 13.5,
    color: color,
    height: 1.35,
  );
}

class ForkTheme {
  // Upstream's colour-scheme setting: index 0 ("Default") becomes PCB gold, the rest keep
  // their colours.
  static Color seedFor(int colorIndex, Color upstreamColor) =>
      colorIndex == 0 ? pcbGold : upstreamColor;

  static ThemeData build(Brightness brightness, Color seed) {
    final dark = brightness == Brightness.dark;
    var scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    if (dark) {
      scheme = scheme.copyWith(
        primary: seed == pcbGold ? pcbGold : scheme.primary,
        onPrimary: seed == pcbGold ? const Color(0xFF221A04) : scheme.onPrimary,
        surface: const Color(0xFF0D0E0B),
        onSurface: const Color(0xFFE6E4DA),
        onSurfaceVariant: const Color(0xFF9D9B8E),
        surfaceContainerLowest: const Color(0xFF090A07),
        surfaceContainerLow: const Color(0xFF121410),
        surfaceContainer: const Color(0xFF161813),
        surfaceContainerHigh: const Color(0xFF1C1E18),
        surfaceContainerHighest: const Color(0xFF23251E),
        outline: const Color(0xFF4A4C40),
        outlineVariant: const Color(0xFF2A2C22),
      );
    }

    const radius = BorderRadius.all(Radius.circular(6));
    const buttonShape = RoundedRectangleBorder(borderRadius: radius);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: scheme.surface,
          statusBarBrightness: brightness,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: buttonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: buttonShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(shape: buttonShape),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        indicatorShape: buttonShape,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        indicatorShape: buttonShape,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: scheme.outlineVariant,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
    return base.useCustomSystemFont(brightness);
  }
}

// Small uppercase monospace label used as a section header (e.g. "HF · 13.56 MHZ").
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;

  const SectionLabel(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 8),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: monoStyle(
                context,
                size: 11.5,
                color: scheme.primary,
              ).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w600),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// Centered icon + title + hint for empty lists and offline states.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.hint,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
