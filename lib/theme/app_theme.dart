import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- NEW DESIGN SYSTEM TOKENS ---

class BrandColors {
  // Primitives
  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const green700 = Color(0xFF15803D);
  static const green900 = Color(0xFF064E3B);
  
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  static const white = Colors.white;
  static const black = Colors.black;

  static const red100 = Color(0xFFFEE2E2);
  static const red500 = Color(0xFFEF4444);
  static const red900 = Color(0xFF7F1D1D);
}

class SemanticColors {
  // Light Mode Semantics
  static const bgLight = BrandColors.slate50;
  static const cardLight = BrandColors.white;
  static const textPrimaryLight = BrandColors.slate900;
  static const textSecondaryLight = BrandColors.slate700;
  static const borderLight = BrandColors.slate200;
  static const primaryLight = BrandColors.green600;

  // Dark Mode Semantics
  static const bgDark = BrandColors.slate900;
  static const cardDark = BrandColors.slate800;
  static const textPrimaryDark = BrandColors.slate50;
  static const textSecondaryDark = BrandColors.slate200;
  static const borderDark = BrandColors.slate700;
  static const primaryDark = BrandColors.green500;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: SemanticColors.bgLight,
      primaryColor: SemanticColors.primaryLight,
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
      colorScheme: const ColorScheme.light(
        primary: SemanticColors.primaryLight,
        surface: SemanticColors.cardLight,
        onSurface: SemanticColors.textPrimaryLight,
        outline: SemanticColors.borderLight,
        error: BrandColors.red500,
      ),
      cardTheme: CardThemeData(
        color: SemanticColors.cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SemanticColors.borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SemanticColors.primaryLight,
          foregroundColor: BrandColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SemanticColors.cardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.primaryLight, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SemanticColors.bgLight,
        foregroundColor: SemanticColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      dividerColor: SemanticColors.borderLight,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SemanticColors.bgDark,
      primaryColor: SemanticColors.primaryDark,
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: SemanticColors.primaryDark,
        surface: SemanticColors.cardDark,
        onSurface: SemanticColors.textPrimaryDark,
        outline: SemanticColors.borderDark,
        error: BrandColors.red500,
      ),
      cardTheme: CardThemeData(
        color: SemanticColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SemanticColors.borderDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SemanticColors.primaryDark,
          foregroundColor: BrandColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SemanticColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SemanticColors.primaryDark, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SemanticColors.bgDark,
        foregroundColor: SemanticColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      dividerColor: SemanticColors.borderDark,
    );
  }
}

// --- LEGACY THEME (For backwards compatibility until full migration) ---

class AppColors {
  static const verde = Color(0xFF16A34A);
  static const verdeEscuro = Color(0xFF15803D);
  static const verdeClaro = Color(0xFFF0FDF4);
  static const verdeBorda = Color(0xFFBBF7D0);
  static const verdeFundoEscuro = Color(0xFF062D24);
  static const verdeCardEscuro = Color(0xFF064E3B);
  static const fundoPagina = Color(0xFFF5F7F9);
  static const fundoPaginaEscuro = Color(0xFF0F172A);
  static const cardEscuro = Color(0xFF1E293B);
  static const bordaEscuro = Color(0xFF334155);
  static const textoPrincipal = Color(0xFF17202A);
  static const textoPrincipalEscuro = Color(0xFFF8FAFC);
  static const textoSecundario = Color(0xFF64748B);
  static const textoSecundarioEscuro = Color(0xFF94A3B8);
  static const bordaCinza = Color(0xFFE5E7EB);
  static const vermelho = Color(0xFFDC2626);
  static const vermelhoClaro = Color(0xFFFEF2F2);
  static const vermelhoFundoEscuro = Color(0xFF381010);
  static const vermelhoBordaEscuro = Color(0xFF7F1D1D);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color getFundoPagina(BuildContext context) => isDark(context) ? fundoPaginaEscuro : fundoPagina;
  static Color getCard(BuildContext context) => isDark(context) ? cardEscuro : Colors.white;
  static Color getTextoPrincipal(BuildContext context) => isDark(context) ? textoPrincipalEscuro : textoPrincipal;
  static Color getTextoSecundario(BuildContext context) => isDark(context) ? textoSecundarioEscuro : textoSecundario;
  static Color getBorda(BuildContext context) => isDark(context) ? bordaEscuro : bordaCinza;
  static Color getVerdeDestaque(BuildContext context) => isDark(context) ? verdeFundoEscuro : verdeClaro;
  static Color getVerdeDestaqueBorda(BuildContext context) => isDark(context) ? const Color(0xFF059669) : verdeBorda;
  static Color getVermelhoDestaque(BuildContext context) => isDark(context) ? vermelhoFundoEscuro : vermelhoClaro;
  static Color getVermelhoDestaqueBorda(BuildContext context) => isDark(context) ? vermelhoBordaEscuro : const Color(0xFFFECACA);
}

final lightTheme = AppTheme.lightTheme;
final darkTheme = AppTheme.darkTheme;