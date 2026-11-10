import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          // No escuro, o verde vivo mantém contraste sobre superfícies profundas.
          primary: isDark ? AppColors.accent : AppColors.primary,
          onPrimary: isDark ? AppColors.primary : Colors.white,
          primaryContainer: isDark ? AppColors.primary : AppColors.accent,
          onPrimaryContainer: isDark ? AppColors.accent : AppColors.primary,
          secondary: isDark ? AppColors.tertiary : AppColors.secondary,
          onSecondary: isDark ? AppColors.primary : Colors.white,
          secondaryContainer: isDark
              ? AppColors.primary
              : const Color(0xFFD6EEDD),
          onSecondaryContainer: isDark
              ? const Color(0xFFD6EEDD)
              : AppColors.primary,
          tertiary: isDark ? AppColors.tertiary : const Color(0xFF006B5C),
          onTertiary: isDark ? AppColors.primary : Colors.white,
          tertiaryContainer: AppColors.tertiary,
          onTertiaryContainer: AppColors.primary,
          surface: isDark ? AppColors.darkSurface : AppColors.surface,
          onSurface: isDark ? const Color(0xFFE4EDE6) : AppColors.textPrimary,
          onSurfaceVariant: isDark
              ? const Color(0xFFB8CBBE)
              : AppColors.textSecondary,
          outline: isDark ? const Color(0xFF8A9E91) : const Color(0xFF6B7E71),
          error: isDark ? const Color(0xFFFFB4AB) : AppColors.danger,
          onError: isDark ? const Color(0xFF690005) : Colors.white,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      // Fonte do sistema (Roboto no Android), a mesma de YouTube e WhatsApp.
      scaffoldBackgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.background,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final buttonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      shape: WidgetStatePropertyAll(shape),
      textStyle: WidgetStatePropertyAll(
        base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    return base.copyWith(
      // Cabeçalho na mesma cor do fundo da tela, sem faixa nem sombra,
      // inclusive ao rolar o conteúdo.
      appBarTheme: AppBarThemeData(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        elevation: 0,
        shape: shape,
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(base.textTheme.labelSmall),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
    );
  }
}
