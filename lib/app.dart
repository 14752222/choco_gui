import 'package:flutter/material.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

// ── Custom theme colors ──────────────────────────────────────────────
const _kPrimaryDark   = Color(0xFF222831); // deep background
const _kSurfaceDark   = Color(0xFF393E46); // card / elevated surface
const _kAccent        = Color(0xFF948979); // primary accent (warm taupe)
const _kOnAccent      = Color(0xFFDFD0B8); // light warm (text / highlights)

/// Root MaterialApp widget. Creates [AppProvider] and wraps the widget tree
/// with [AppProviderScope] so all descendants can call
/// [AppProviderScope.of(context)].
class ChocoApp extends StatefulWidget {
  const ChocoApp({super.key});

  @override
  State<ChocoApp> createState() => _ChocoAppState();
}

class _ChocoAppState extends State<ChocoApp> {
  final AppProvider _provider = AppProvider();

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppProviderScope(
      provider: _provider,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _provider.themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'Chocolatey GUI',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  /// Light theme – uses the warm accent family with bright surfaces.
  ThemeData _buildLightTheme() {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: _kAccent,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFEEE8E2),
      onPrimaryContainer: Color(0xFF332E28),
      secondary: _kAccent,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFF0EBE5),
      onSecondaryContainer: Color(0xFF332E28),
      surface: Color(0xFFFFFBF7),
      onSurface: Color(0xFF1C1B19),
      surfaceContainerHighest: Color(0xFFF0EBE5),
      error: Color(0xFFBA1A1A),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFF8E8780),
      outlineVariant: Color(0xFFD5CEC6),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      navigationRailTheme: const NavigationRailThemeData(useIndicator: true),
    );
  }

  /// Dark theme – uses the user-supplied four-colour palette.
  ThemeData _buildDarkTheme() {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: _kOnAccent,
      onPrimary: _kPrimaryDark,
      primaryContainer: Color(0xFF4A4F58),
      onPrimaryContainer: _kOnAccent,
      secondary: _kOnAccent.withAlpha(220),
      onSecondary: _kPrimaryDark,
      secondaryContainer: Color(0xFF4A4F58),
      onSecondaryContainer: _kOnAccent,
      surface: _kPrimaryDark,
      onSurface: _kOnAccent,
      surfaceContainerHighest: _kSurfaceDark,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      outline: Color(0xFF7E858F),
      outlineVariant: Color(0xFF3C414A),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: _kPrimaryDark,
      navigationRailTheme: const NavigationRailThemeData(useIndicator: true),
      appBarTheme: const AppBarTheme(
        backgroundColor: _kSurfaceDark,
        foregroundColor: _kOnAccent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: _kSurfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF4A4F58)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _kSurfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _kSurfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4A4F58)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kOnAccent, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF4A4F58),
        selectedColor: _kOnAccent.withAlpha(30),
        labelStyle: const TextStyle(color: _kOnAccent),
      ),
    );
  }
}
