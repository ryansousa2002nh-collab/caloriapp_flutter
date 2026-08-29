import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Cores do aplicativo (Claro & Escuro)
class AppColors {
  // Marca e destaques
  static const verde = Color(0xFF16A34A);       // botões, destaques
  static const verdeEscuro = Color(0xFF15803D); // hover, texto de destaque
  static const verdeClaro = Color(0xFFF0FDF4);  // fundo de destaque claro
  static const verdeBorda = Color(0xFFBBF7D0);  // borda de destaque claro
  static const verdeFundoEscuro = Color(0xFF062D24);
  static const verdeCardEscuro = Color(0xFF064E3B);

  // Paleta de fundo e superfícies
  static const fundoPagina = Color(0xFFF5F7F9);
  static const fundoPaginaEscuro = Color(0xFF0F172A); // Slate 900
  static const cardEscuro = Color(0xFF1E293B);        // Slate 800
  static const bordaEscuro = Color(0xFF334155);       // Slate 700

  // Textos
  static const textoPrincipal = Color(0xFF17202A);
  static const textoPrincipalEscuro = Color(0xFFF8FAFC);
  static const textoSecundario = Color(0xFF64748B);
  static const textoSecundarioEscuro = Color(0xFF94A3B8);

  // Bordas e Alertas
  static const bordaCinza = Color(0xFFE5E7EB);
  static const vermelho = Color(0xFFDC2626);
  static const vermelhoClaro = Color(0xFFFEF2F2);
  static const vermelhoFundoEscuro = Color(0xFF381010);
  static const vermelhoBordaEscuro = Color(0xFF7F1D1D);

  // Helpers contextuais para adaptação fluida
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getFundoPagina(BuildContext context) =>
      isDark(context) ? fundoPaginaEscuro : fundoPagina;

  static Color getCard(BuildContext context) =>
      isDark(context) ? cardEscuro : Colors.white;

  static Color getTextoPrincipal(BuildContext context) =>
      isDark(context) ? textoPrincipalEscuro : textoPrincipal;

  static Color getTextoSecundario(BuildContext context) =>
      isDark(context) ? textoSecundarioEscuro : textoSecundario;

  static Color getBorda(BuildContext context) =>
      isDark(context) ? bordaEscuro : bordaCinza;

  static Color getVerdeDestaque(BuildContext context) =>
      isDark(context) ? verdeFundoEscuro : verdeClaro;

  static Color getVerdeDestaqueBorda(BuildContext context) =>
      isDark(context) ? const Color(0xFF059669) : verdeBorda;

  static Color getVermelhoDestaque(BuildContext context) =>
      isDark(context) ? vermelhoFundoEscuro : vermelhoClaro;

  static Color getVermelhoDestaqueBorda(BuildContext context) =>
      isDark(context) ? vermelhoBordaEscuro : const Color(0xFFFECACA);
}

final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.fundoPagina,
  primaryColor: AppColors.verde,
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.verde,
    primary: AppColors.verde,
    brightness: Brightness.light,
    surface: Colors.white,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.bordaCinza),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.verde,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: AppColors.textoPrincipal,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textoPrincipal),
  ),
  dividerColor: AppColors.bordaCinza,
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.fundoPaginaEscuro,
  primaryColor: AppColors.verde,
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.verde,
    primary: AppColors.verde,
    brightness: Brightness.dark,
    surface: AppColors.cardEscuro,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardEscuro,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.bordaEscuro),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.verde,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.cardEscuro,
    foregroundColor: AppColors.textoPrincipalEscuro,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.textoPrincipalEscuro),
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: AppColors.cardEscuro,
  ),
  dividerColor: AppColors.bordaEscuro,
  inputDecorationTheme: InputDecorationTheme(
    fillColor: AppColors.cardEscuro,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.bordaEscuro),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.bordaEscuro),
    ),
  ),
);

// Compatibilidade
final appTheme = lightTheme;