import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Cores extraídas do seu CSS
class AppColors {
  static const verde = Color(0xFF16A34A);       // botões, destaques
  static const verdeEscuro = Color(0xFF15803D); // hover, texto de destaque
  static const verdeClaro = Color(0xFFF0FDF4);  // fundo de destaque (calorias, nav ativo)
  static const verdeBorda = Color(0xFFBBF7D0);  // borda de destaque
  static const fundoPagina = Color(0xFFF5F7F9);
  static const textoPrincipal = Color(0xFF17202A);
  static const textoSecundario = Color(0xFF64748B);
  static const bordaCinza = Color(0xFFE5E7EB);
  static const vermelho = Color(0xFFDC2626);
  static const vermelhoClaro = Color(0xFFFEF2F2);
}

final appTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.fundoPagina,
  primaryColor: AppColors.verde,
  fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.verde,
    primary: AppColors.verde,
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
  ),
);