import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Borda arredondada para campos de texto que mantém o rótulo (labelText)
/// perfeitamente alinhado dentro do campo e alinhado com o texto/ícone,
/// sem cortar a borda superior nem vazar para o fundo verde.
class RoundedInputBorder extends InputBorder {
  final BorderRadius borderRadius;

  const RoundedInputBorder({
    super.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
  });

  @override
  bool get isOutline => false;

  @override
  RoundedInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
  }) {
    return RoundedInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  RoundedInputBorder scale(double t) {
    return RoundedInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRRect(
        borderRadius.resolve(textDirection).toRRect(rect).deflate(borderSide.width),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none) return;
    final RRect outer = borderRadius.resolve(textDirection).toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);
    canvas.drawRRect(center, borderSide.toPaint());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is RoundedInputBorder &&
        other.borderSide == borderSide &&
        other.borderRadius == borderRadius;
  }

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}

// --- NEW DESIGN SYSTEM TOKENS (BOTANICAL PALETTE) ---

class BrandColors {
  // Primitives - Botanical Sage & Olive Palette
  static const green50 = Color(0xFFF4F6EF);
  static const green100 = Color(0xFFE3EAD8);
  static const green500 = Color(0xFF6B8450);
  static const green600 = Color(0xFF4A6234);
  static const green700 = Color(0xFF3B4F29);
  static const green900 = Color(0xFF1F2B16);

  static const slate50 = Color(0xFFFAF9F5);
  static const slate100 = Color(0xFFF1F3EB);
  static const slate200 = Color(0xFFD8DFC9);
  static const slate700 = Color(0xFF2E3F24);
  static const slate800 = Color(0xFF1D291E);
  static const slate900 = Color(0xFF141E15);

  static const white = Colors.white;
  static const black = Colors.black;

  static const red100 = Color(0xFFFEE2E2);
  static const red500 = Color(0xFFEF4444);
  static const red900 = Color(0xFF7F1D1D);

  // Culinary & Editorial Accents (Layer 1 Primitives)
  static const amber400 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const berry500 = Color(0xFFE1306C);
  static const berry600 = Color(0xFFE11D48);
  static const plum600 = Color(0xFF833AB4);
  static const citrus500 = Color(0xFFF77737);
  static const mint300 = Color(0xFF86EFAC);
}

class SemanticColors {
  // Light Mode Semantics (harmonized with Botanical Sage background)
  static const bgLight = Color(0xFF91A47B);
  static const cardLight = Color(0xFFF9FAF6);
  static const textPrimaryLight = Color(0xFF1E2D16);
  static const textSecondaryLight = Color(0xFF314426);
  static const borderLight = Color(0xFFD5DEC6);
  static const primaryLight = Color(0xFF42582E);
  static const highlightSurfaceLight = Color(0xFFEDF2E4);
  static const highlightBorderLight = Color(0xFFC5D3B0);
  static const socialAccentLight = BrandColors.berry500;
  static const likeActiveLight = BrandColors.berry600;

  // Dark Mode Semantics
  static const bgDark = Color(0xFF162117);
  static const cardDark = Color(0xFF1F2E20);
  static const textPrimaryDark = Color(0xFFF4F6F0);
  static const textSecondaryDark = Color(0xFFC5D0B5);
  static const borderDark = Color(0xFF344935);
  static const primaryDark = Color(0xFF7D9660);
  static const highlightSurfaceDark = Color(0xFF213322);
  static const highlightBorderDark = Color(0xFF4A6B46);
  static const socialAccentDark = BrandColors.berry500;
  static const likeActiveDark = BrandColors.berry600;
}

/// Layer 3 Component Tokens for the Comunidade Module (design-system skill)
@immutable
class ComunidadeTheme extends ThemeExtension<ComunidadeTheme> {
  final Color cardSurface;
  final Color cardBorder;
  final Color highlightSurface;
  final Color highlightBorder;
  final Color categoryTagText;
  final Color socialAccent;
  final Color likeActive;
  final Color citrusStart;
  final Color citrusEnd;

  const ComunidadeTheme({
    required this.cardSurface,
    required this.cardBorder,
    required this.highlightSurface,
    required this.highlightBorder,
    required this.categoryTagText,
    required this.socialAccent,
    required this.likeActive,
    required this.citrusStart,
    required this.citrusEnd,
  });

  static final light = ComunidadeTheme(
    cardSurface: SemanticColors.cardLight.withValues(alpha: 0.94),
    cardBorder: SemanticColors.borderLight,
    highlightSurface: SemanticColors.highlightSurfaceLight,
    highlightBorder: SemanticColors.highlightBorderLight,
    categoryTagText: BrandColors.green700,
    socialAccent: SemanticColors.socialAccentLight,
    likeActive: SemanticColors.likeActiveLight,
    citrusStart: BrandColors.amber400,
    citrusEnd: BrandColors.amber600,
  );

  static final dark = ComunidadeTheme(
    cardSurface: SemanticColors.cardDark.withValues(alpha: 0.92),
    cardBorder: SemanticColors.borderDark,
    highlightSurface: SemanticColors.highlightSurfaceDark,
    highlightBorder: SemanticColors.highlightBorderDark,
    categoryTagText: BrandColors.mint300,
    socialAccent: SemanticColors.socialAccentDark,
    likeActive: SemanticColors.likeActiveDark,
    citrusStart: BrandColors.amber400,
    citrusEnd: BrandColors.amber600,
  );

  static ComunidadeTheme of(BuildContext context) {
    return Theme.of(context).extension<ComunidadeTheme>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  @override
  ComunidadeTheme copyWith({
    Color? cardSurface,
    Color? cardBorder,
    Color? highlightSurface,
    Color? highlightBorder,
    Color? categoryTagText,
    Color? socialAccent,
    Color? likeActive,
    Color? citrusStart,
    Color? citrusEnd,
  }) {
    return ComunidadeTheme(
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      highlightSurface: highlightSurface ?? this.highlightSurface,
      highlightBorder: highlightBorder ?? this.highlightBorder,
      categoryTagText: categoryTagText ?? this.categoryTagText,
      socialAccent: socialAccent ?? this.socialAccent,
      likeActive: likeActive ?? this.likeActive,
      citrusStart: citrusStart ?? this.citrusStart,
      citrusEnd: citrusEnd ?? this.citrusEnd,
    );
  }

  @override
  ComunidadeTheme lerp(ThemeExtension<ComunidadeTheme>? other, double t) {
    if (other is! ComunidadeTheme) return this;
    return ComunidadeTheme(
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      highlightSurface: Color.lerp(highlightSurface, other.highlightSurface, t)!,
      highlightBorder: Color.lerp(highlightBorder, other.highlightBorder, t)!,
      categoryTagText: Color.lerp(categoryTagText, other.categoryTagText, t)!,
      socialAccent: Color.lerp(socialAccent, other.socialAccent, t)!,
      likeActive: Color.lerp(likeActive, other.likeActive, t)!,
      citrusStart: Color.lerp(citrusStart, other.citrusStart, t)!,
      citrusEnd: Color.lerp(citrusEnd, other.citrusEnd, t)!,
    );
  }
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
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: SemanticColors.primaryLight,
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: SemanticColors.textPrimaryLight,
        displayColor: SemanticColors.textPrimaryLight,
      ),
      colorScheme: const ColorScheme.light(
        primary: SemanticColors.primaryLight,
        surface: SemanticColors.cardLight,
        onSurface: SemanticColors.textPrimaryLight,
        outline: SemanticColors.borderLight,
        error: BrandColors.red500,
      ),
      cardTheme: CardThemeData(
        color: SemanticColors.cardLight.withValues(alpha: 0.92),
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
        fillColor: SemanticColors.cardLight.withValues(alpha: 0.94),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIconColor: SemanticColors.primaryLight,
        suffixIconColor: SemanticColors.textSecondaryLight,
        labelStyle: GoogleFonts.outfit(
          color: SemanticColors.textSecondaryLight,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.outfit(
          color: SemanticColors.primaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: SemanticColors.borderLight),
        ),
        enabledBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: SemanticColors.borderLight),
        ),
        focusedBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: SemanticColors.primaryLight, width: 2),
        ),
        errorBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: BrandColors.red500),
        ),
        focusedErrorBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: BrandColors.red500, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SemanticColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      dividerColor: SemanticColors.borderLight,
      extensions: <ThemeExtension<dynamic>>[
        ComunidadeTheme.light,
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: SemanticColors.primaryDark,
      fontFamily: GoogleFonts.outfit().fontFamily,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: SemanticColors.textPrimaryDark,
        displayColor: SemanticColors.textPrimaryDark,
      ),
      colorScheme: const ColorScheme.dark(
        primary: SemanticColors.primaryDark,
        surface: SemanticColors.cardDark,
        onSurface: SemanticColors.textPrimaryDark,
        outline: SemanticColors.borderDark,
        error: BrandColors.red500,
      ),
      cardTheme: CardThemeData(
        color: SemanticColors.cardDark.withValues(alpha: 0.90),
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
        fillColor: SemanticColors.cardDark.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIconColor: SemanticColors.primaryDark,
        suffixIconColor: SemanticColors.textSecondaryDark,
        labelStyle: GoogleFonts.outfit(
          color: SemanticColors.textSecondaryDark,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.outfit(
          color: SemanticColors.primaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: SemanticColors.borderDark),
        ),
        enabledBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: SemanticColors.borderDark),
        ),
        focusedBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: SemanticColors.primaryDark, width: 2),
        ),
        errorBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: BrandColors.red500),
        ),
        focusedErrorBorder: const RoundedInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: BrandColors.red500, width: 2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SemanticColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      dividerColor: SemanticColors.borderDark,
      extensions: <ThemeExtension<dynamic>>[
        ComunidadeTheme.dark,
      ],
    );
  }
}

// --- LEGACY THEME (Harmonized with Botanical Theme) ---

class AppColors {
  static const verde = Color(0xFF42582E);
  static const verdeEscuro = Color(0xFF2F4220);
  static const verdeClaro = Color(0xFFEDF2E4);
  static const verdeBorda = Color(0xFFC5D3B0);
  static const verdeFundoEscuro = Color(0xFF213322);
  static const verdeCardEscuro = Color(0xFF293E2A);
  static const fundoPagina = Color(0xFF91A47B);
  static const fundoPaginaEscuro = Color(0xFF162117);
  static const cardEscuro = Color(0xFF1F2E20);
  static const bordaEscuro = Color(0xFF344935);
  static const textoPrincipal = Color(0xFF1E2D16);
  static const textoPrincipalEscuro = Color(0xFFF4F6F0);
  static const textoSecundario = Color(0xFF314426);
  static const textoSecundarioEscuro = Color(0xFFC5D0B5);
  static const bordaCinza = Color(0xFFD5DEC6);
  static const vermelho = Color(0xFFDC2626);
  static const vermelhoClaro = Color(0xFFFEF2F2);
  static const vermelhoFundoEscuro = Color(0xFF381010);
  static const vermelhoBordaEscuro = Color(0xFF7F1D1D);

  // Tom rosa das frutinhas do tema botânico
  static const rosaFrutinha = Color(0xFFDF9E99);
  static const rosaFrutinhaClaro = Color(0xFFF1C0BC);
  static const rosaFrutinhaEscuro = Color(0xFFCE8882);
  static const rosaFrutinhaFundoEscuro = Color(0xFFE5A8A3);
  static const rosaVibrante = Color(0xFFF43F5E); // Rosa chamativo vibrante
  static const rosaVibranteEscuro = Color(0xFFFB7185);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color getFundoPagina(BuildContext context) => isDark(context) ? fundoPaginaEscuro : fundoPagina;
  static Color getCard(BuildContext context) =>
      isDark(context) ? cardEscuro.withValues(alpha: 0.92) : const Color(0xFFF9FAF6).withValues(alpha: 0.92);
  static Color getTextoPrincipal(BuildContext context) => isDark(context) ? textoPrincipalEscuro : textoPrincipal;
  static Color getTextoSecundario(BuildContext context) => isDark(context) ? textoSecundarioEscuro : textoSecundario;
  static Color getBorda(BuildContext context) => isDark(context) ? bordaEscuro : bordaCinza;
  static Color getVerdeDestaque(BuildContext context) => isDark(context) ? verdeFundoEscuro : verdeClaro;
  static Color getVerdeDestaqueBorda(BuildContext context) => isDark(context) ? const Color(0xFF4A6B46) : verdeBorda;
  static Color getVermelhoDestaque(BuildContext context) => isDark(context) ? vermelhoFundoEscuro : vermelhoClaro;
  static Color getVermelhoDestaqueBorda(BuildContext context) => isDark(context) ? vermelhoBordaEscuro : const Color(0xFFFECACA);
}

final lightTheme = AppTheme.lightTheme;
final darkTheme = AppTheme.darkTheme;
