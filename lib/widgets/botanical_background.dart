import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Fundo botânico desenhado 100% via código com (CustomPainter),
/// reproduzindo a arte em aquarela verde-sálvia com ramos de oliveira,
/// folhas bicolores, frutinhas rosadas e linhas orgânicas creme.
class BotanicalBackground extends StatelessWidget {
  final Widget child;

  const BotanicalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomPaint(
      painter: BotanicalBackgroundPainter(isDark: isDark),
      child: child,
    );
  }
}

class BotanicalBackgroundPainter extends CustomPainter {
  final bool isDark;

  const BotanicalBackgroundPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    // 1. Base em tom verde-sálvia aquarelado (ou verde-floresta profundo no modo escuro)
    _paintBaseBackground(canvas, size);

    // 2. Manchas e ondas orgânicas de aquarela nos cantos e bordas
    _paintWatercolorWaves(canvas, size);

    // 3. Ramos e folhas em silhueta suave ao fundo (camada secundária)
    _paintBackgroundSilhouettes(canvas, size);

    // 4. Linhas orgânicas finas em tom creme/off-white
    _paintFlowingCreamLines(canvas, size);

    // 5. Ramos botânicos principais detalhados (canto superior esquerdo e inferior direito)
    _paintTopLeftBranch(canvas, size);
    _paintBottomRightBranch(canvas, size);

    canvas.restore();
  }

  void _paintBaseBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final baseColors = isDark
        ? [
            const Color(0xFF1E2B1E),
            const Color(0xFF162117),
            const Color(0xFF121B13),
          ]
        : [
            const Color(0xFF99AB83),
            const Color(0xFF91A47B),
            const Color(0xFF889B72),
          ];

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.1, -0.05),
        radius: 1.15,
        colors: baseColors,
        stops: const [0.0, 0.65, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _paintWatercolorWaves(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final lightWave1 = isDark
        ? const Color(0xFF2D3F2C).withValues(alpha: 0.45)
        : const Color(0xFFCFD9BE).withValues(alpha: 0.42);
    final lightWave2 = isDark
        ? const Color(0xFF263626).withValues(alpha: 0.38)
        : const Color(0xFFBCCAA7).withValues(alpha: 0.36);
    final darkWave = isDark
        ? const Color(0xFF0D150E).withValues(alpha: 0.50)
        : const Color(0xFF72875B).withValues(alpha: 0.35);

    // Onda escura lateral esquerda
    final leftDarkPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.14, 0)
      ..cubicTo(w * 0.10, h * 0.12, w * 0.02, h * 0.22, w * 0.06, h * 0.36)
      ..cubicTo(w * 0.09, h * 0.48, w * 0.01, h * 0.58, w * 0.05, h * 0.72)
      ..cubicTo(w * 0.08, h * 0.80, w * 0.02, h * 0.88, 0, h * 0.92)
      ..close();
    canvas.drawPath(leftDarkPath, Paint()..color = darkWave);

    // Onda clara superior esquerda
    final topLeftLightPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.19, 0)
      ..cubicTo(w * 0.21, h * 0.10, w * 0.16, h * 0.20, w * 0.10, h * 0.28)
      ..cubicTo(w * 0.05, h * 0.35, w * 0.14, h * 0.42, w * 0.11, h * 0.50)
      ..cubicTo(w * 0.08, h * 0.56, w * 0.03, h * 0.57, 0, h * 0.59)
      ..close();
    canvas.drawPath(topLeftLightPath, Paint()..color = lightWave2);

    // Onda clara inferior esquerda (camada maior)
    final bottomLeftWave1 = Path()
      ..moveTo(0, h * 0.65)
      ..cubicTo(w * 0.07, h * 0.68, w * 0.12, h * 0.78, w * 0.20, h * 0.86)
      ..cubicTo(w * 0.28, h * 0.93, w * 0.36, h * 0.95, w * 0.42, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(bottomLeftWave1, Paint()..color = lightWave2);

    // Onda mais clara no canto inferior esquerdo
    final bottomLeftWave2 = Path()
      ..moveTo(0, h * 0.78)
      ..cubicTo(w * 0.10, h * 0.79, w * 0.19, h * 0.88, w * 0.31, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(bottomLeftWave2, Paint()..color = lightWave1);

    // Onda clara superior direita
    final topRightWave = Path()
      ..moveTo(w * 0.82, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h * 0.36)
      ..cubicTo(w * 0.93, h * 0.27, w * 0.85, h * 0.19, w * 0.82, 0)
      ..close();
    canvas.drawPath(topRightWave, Paint()..color = lightWave1);

    // Onda suave direita inferior
    final rightMidWave = Path()
      ..moveTo(w, h * 0.38)
      ..cubicTo(w * 0.91, h * 0.46, w * 0.89, h * 0.62, w * 0.94, h * 0.75)
      ..lineTo(w, h * 0.82)
      ..close();
    canvas.drawPath(rightMidWave, Paint()..color = lightWave2);

    // Onda clara canto inferior direito
    final bottomRightWave = Path()
      ..moveTo(w * 0.72, h)
      ..cubicTo(w * 0.78, h * 0.90, w * 0.89, h * 0.86, w, h * 0.75)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(bottomRightWave, Paint()..color = lightWave1);
  }

  void _paintBackgroundSilhouettes(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ref = math.min(w, h);

    final silhouetteOlive = isDark
        ? const Color(0xFF2B3E2A).withValues(alpha: 0.45)
        : const Color(0xFF7B9063).withValues(alpha: 0.42);
    final silhouetteLight = isDark
        ? const Color(0xFF394F37).withValues(alpha: 0.35)
        : const Color(0xFFC5D0B2).withValues(alpha: 0.45);

    // --- Silhueta de ramo no canto superior direito ---
    final trStemPaint = Paint()
      ..color = silhouetteOlive
      ..style = PaintingStyle.stroke
      ..strokeWidth = ref * 0.003
      ..strokeCap = StrokeCap.round;

    final trStem = Path()
      ..moveTo(w, h * 0.33)
      ..cubicTo(w * 0.96, h * 0.22, w * 0.88, h * 0.15, w * 0.77, h * 0.09);
    canvas.drawPath(trStem, trStemPaint);

    // Folhas da silhueta superior direita
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.80, h * 0.11),
      angle: -2.35,
      length: ref * 0.10,
      width: ref * 0.036,
      color: silhouetteOlive,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.83, h * 0.14),
      angle: -1.45,
      length: ref * 0.11,
      width: ref * 0.038,
      color: silhouetteOlive,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.84, h * 0.15),
      angle: -2.85,
      length: ref * 0.12,
      width: ref * 0.042,
      color: silhouetteOlive,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.90, h * 0.19),
      angle: -1.60,
      length: ref * 0.11,
      width: ref * 0.040,
      color: silhouetteOlive,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.92, h * 0.21),
      angle: -2.75,
      length: ref * 0.12,
      width: ref * 0.042,
      color: silhouetteOlive,
    );

    // --- Silhueta lateral direita média ---
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.97, h * 0.56),
      angle: -2.10,
      length: ref * 0.16,
      width: ref * 0.058,
      color: silhouetteLight,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.98, h * 0.52),
      angle: -1.55,
      length: ref * 0.14,
      width: ref * 0.050,
      color: silhouetteLight,
    );

    // --- Silhueta de folhas no canto inferior esquerdo ---
    final blStem = Path()
      ..moveTo(0, h * 0.85)
      ..quadraticBezierTo(w * 0.06, h * 0.81, w * 0.11, h * 0.76);
    canvas.drawPath(blStem, trStemPaint);

    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.06, h * 0.80),
      angle: -1.75,
      length: ref * 0.15,
      width: ref * 0.055,
      color: silhouetteOlive,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.08, h * 0.79),
      angle: -1.05,
      length: ref * 0.16,
      width: ref * 0.058,
      color: silhouetteOlive,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.09, h * 0.81),
      angle: -0.45,
      length: ref * 0.16,
      width: ref * 0.056,
      color: silhouetteOlive,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.07, h * 0.83),
      angle: 0.45,
      length: ref * 0.14,
      width: ref * 0.052,
      color: silhouetteOlive,
    );

    // --- Folhas claras translúcidas na base direita (atrás do ramo principal) ---
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.73, h * 0.92),
      angle: -2.95,
      length: ref * 0.22,
      width: ref * 0.072,
      color: silhouetteLight,
      drawVein: true,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.76, h * 0.90),
      angle: -2.35,
      length: ref * 0.20,
      width: ref * 0.065,
      color: silhouetteLight,
      drawVein: true,
    );
  }

  void _paintFlowingCreamLines(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ref = math.min(w, h);

    final creamLinePaint = Paint()
      ..color = isDark
          ? const Color(0xFFDCE3CE).withValues(alpha: 0.28)
          : const Color(0xFFECEFE4).withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (ref * 0.0038).clamp(1.6, 3.0)
      ..strokeCap = StrokeCap.round;

    // Linha contínua orgânica da borda esquerda até a borda inferior
    final leftBottomCurve = Path()
      ..moveTo(0, h * 0.428)
      ..cubicTo(w * 0.09, h * 0.48, w * 0.075, h * 0.58, w * 0.055, h * 0.67)
      ..cubicTo(w * 0.038, h * 0.76, w * 0.09, h * 0.87, w * 0.22, h * 0.895)
      ..cubicTo(w * 0.34, h * 0.915, w * 0.40, h * 0.94, w * 0.455, h);
    canvas.drawPath(leftBottomCurve, creamLinePaint);

    // Linha orgânica no canto superior direito
    final topRightCurve = Path()
      ..moveTo(w * 0.74, 0)
      ..cubicTo(w * 0.80, h * 0.05, w * 0.92, h * 0.07, w, h * 0.165);
    canvas.drawPath(topRightCurve, creamLinePaint);
  }

  void _paintTopLeftBranch(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ref = math.min(w, h);

    final creamLeafColor = isDark
        ? const Color(0xFF475E43).withValues(alpha: 0.65)
        : const Color(0xFFDCE3CE).withValues(alpha: 0.78);
    final softSageLeafColor = isDark
        ? const Color(0xFF384D35).withValues(alpha: 0.60)
        : const Color(0xFFB5C39F).withValues(alpha: 0.68);

    // 1. Folhas aquareladas claras de fundo do ramo superior esquerdo
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.10, h * 0.01),
      angle: 1.15,
      length: ref * 0.16,
      width: ref * 0.068,
      color: creamLeafColor,
      drawVein: true,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.18, h * 0.11),
      angle: -0.95,
      length: ref * 0.17,
      width: ref * 0.064,
      color: creamLeafColor,
      drawVein: true,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.16, h * 0.13),
      angle: 0.68,
      length: ref * 0.19,
      width: ref * 0.066,
      color: softSageLeafColor,
      drawVein: true,
    );

    // 2. Folhas contornadas e bicolores (ramo superior esquerdo)
    // Ramo secundário que desce à esquerda
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.052, h * 0.072),
      angle: 1.62,
      length: ref * 0.18,
      width: ref * 0.062,
      bend: -0.08,
    );
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.088, h * 0.125),
      angle: 1.05,
      length: ref * 0.165,
      width: ref * 0.054,
      bend: 0.06,
    );
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.085, h * 0.195),
      angle: 1.24,
      length: ref * 0.165,
      width: ref * 0.052,
      isPaleHalf: true,
      bend: -0.05,
    );

    // Ramo principal que vai para a direita
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.145, h * 0.112),
      angle: -0.58,
      length: ref * 0.13,
      width: ref * 0.044,
      bend: 0.05,
    );
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.198, h * 0.108),
      angle: 0.40,
      length: ref * 0.175,
      width: ref * 0.060,
      bend: 0.08,
    );
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.242, h * 0.092),
      angle: -0.72,
      length: ref * 0.145,
      width: ref * 0.048,
      isPaleHalf: true,
      bend: 0.06,
    );
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.325, h * 0.080),
      angle: 0.25,
      length: ref * 0.15,
      width: ref * 0.048,
      isPaleHalf: true,
      bend: 0.05,
    );

    // 3. Galhos principais (traço verde-oliva escuro)
    final stemColor = isDark
        ? const Color(0xFF8AA674)
        : const Color(0xFF42562C);
    final mainStemPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (ref * 0.0042).clamp(1.6, 3.2)
      ..strokeCap = StrokeCap.round;

    final mainTopStem = Path()
      ..moveTo(0, h * 0.008)
      ..cubicTo(w * 0.08, h * 0.075, w * 0.16, h * 0.125, w * 0.25, h * 0.095)
      ..quadraticBezierTo(w * 0.30, h * 0.078, w * 0.34, h * 0.082);
    canvas.drawPath(mainTopStem, mainStemPaint);

    final subLeftStem = Path()
      ..moveTo(w * 0.025, h * 0.032)
      ..cubicTo(
        w * 0.065,
        h * 0.08,
        w * 0.082,
        h * 0.145,
        w * 0.092,
        h * 0.215,
      );
    canvas.drawPath(subLeftStem, mainStemPaint);

    // 4. Frutinhas rosadas (berries) no ramo superior esquerdo
    final berryRadius = (ref * 0.0115).clamp(4.5, 9.0);
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.072, h * 0.064),
      center: Offset(w * 0.098, h * 0.085),
      radius: berryRadius,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.078, h * 0.185),
      center: Offset(w * 0.068, h * 0.242),
      radius: berryRadius,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.155, h * 0.115),
      center: Offset(w * 0.190, h * 0.170),
      radius: berryRadius,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.305, h * 0.082),
      center: Offset(w * 0.356, h * 0.115),
      radius: berryRadius,
    );
  }

  void _paintBottomRightBranch(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ref = math.min(w, h);

    final creamLeafColor = isDark
        ? const Color(0xFF475E43).withValues(alpha: 0.65)
        : const Color(0xFFE0E6D4).withValues(alpha: 0.82);

    // 1. Folhas claras aquareladas atrás do ramo inferior direito
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.92, h * 0.78),
      angle: -1.18,
      length: ref * 0.175,
      width: ref * 0.062,
      color: creamLeafColor,
      drawVein: true,
    );
    _drawSilhouetteLeaf(
      canvas,
      Offset(w * 0.93, h * 0.835),
      angle: -2.62,
      length: ref * 0.18,
      width: ref * 0.064,
      color: creamLeafColor,
      drawVein: true,
    );

    // 2. Folhas contornadas e bicolores (ramo inferior direito)
    // Folha do topo apontando para cima/esquerda
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.892, h * 0.685),
      angle: -1.92,
      length: ref * 0.175,
      width: ref * 0.058,
      isPaleHalf: true,
      bend: 0.07,
    );
    // Folha superior esquerda apontando para a esquerda
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.908, h * 0.742),
      angle: -2.72,
      length: ref * 0.165,
      width: ref * 0.050,
      bend: -0.06,
    );
    // Folha lateral direita
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.955, h * 0.855),
      angle: -0.95,
      length: ref * 0.14,
      width: ref * 0.052,
      bend: 0.05,
    );
    // Folha média-central apontando para cima/esquerda
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.915, h * 0.865),
      angle: -2.55,
      length: ref * 0.20,
      width: ref * 0.064,
      bend: 0.08,
    );
    // Folha inferior esquerda apontando para baixo/esquerda
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.838, h * 0.878),
      angle: 2.58,
      length: ref * 0.19,
      width: ref * 0.058,
      isPaleHalf: true,
      bend: -0.06,
    );
    // Folha da base direita
    _drawDetailedLeaf(
      canvas,
      base: Offset(w * 0.962, h * 0.932),
      angle: 2.75,
      length: ref * 0.155,
      width: ref * 0.050,
      bend: 0.05,
    );

    // 3. Galhos principais do canto inferior direito
    final stemColor = isDark
        ? const Color(0xFF8AA674)
        : const Color(0xFF42562C);
    final mainStemPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (ref * 0.0044).clamp(1.6, 3.2)
      ..strokeCap = StrokeCap.round;

    final mainRightStem = Path()
      ..moveTo(w, h * 0.965)
      ..cubicTo(w * 0.965, h * 0.89, w * 0.935, h * 0.78, w * 0.89, h * 0.675);
    canvas.drawPath(mainRightStem, mainStemPaint);

    final subBottomStem = Path()
      ..moveTo(w * 0.975, h * 0.92)
      ..cubicTo(w * 0.92, h * 0.865, w * 0.86, h * 0.865, w * 0.79, h * 0.885);
    canvas.drawPath(subBottomStem, mainStemPaint);

    // 4. Frutinhas rosadas (berries) no ramo inferior direito
    final berryRadius = (ref * 0.0115).clamp(4.5, 9.0);
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.88, h * 0.71),
      center: Offset(w * 0.822, h * 0.672),
      radius: berryRadius,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.922, h * 0.805),
      center: Offset(w * 0.862, h * 0.772),
      radius: berryRadius,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.945, h * 0.81),
      center: Offset(w * 0.968, h * 0.752),
      radius: berryRadius * 0.9,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.805, h * 0.868),
      center: Offset(w * 0.746, h * 0.852),
      radius: berryRadius * 0.9,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.795, h * 0.876),
      center: Offset(w * 0.742, h * 0.878),
      radius: berryRadius * 0.95,
    );
    _drawBerry(
      canvas,
      stemStart: Offset(w * 0.948, h * 0.902),
      center: Offset(w * 0.908, h * 0.906),
      radius: berryRadius,
    );
  }

  void _drawSilhouetteLeaf(
    Canvas canvas,
    Offset base, {
    required double angle,
    required double length,
    required double width,
    required Color color,
    bool drawVein = false,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        length * 0.28,
        -width * 0.62,
        length * 0.68,
        -width * 0.48,
        length,
        0,
      )
      ..cubicTo(length * 0.68, width * 0.48, length * 0.28, width * 0.62, 0, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = color);

    if (drawVein) {
      final veinPaint = Paint()
        ..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final vein = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(length * 0.5, -width * 0.04, length * 0.88, 0);
      canvas.drawPath(vein, veinPaint);
    }

    canvas.restore();
  }

  void _drawDetailedLeaf(
    Canvas canvas, {
    required Offset base,
    required double angle,
    required double length,
    required double width,
    bool isPaleHalf = false,
    double bend = 0.05,
  }) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);

    final tipY = length * bend;

    // Caminho completo da folha
    final fullLeaf = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        length * 0.25,
        -width * 0.58,
        length * 0.65,
        -width * 0.45 + tipY * 0.5,
        length,
        tipY,
      )
      ..cubicTo(
        length * 0.65,
        width * 0.52 + tipY * 0.5,
        length * 0.25,
        width * 0.58,
        0,
        0,
      )
      ..close();

    // Preenchimento base verde-oliva aquarelado
    final baseFillColor = isDark
        ? const Color(0xFF31472E).withValues(alpha: 0.88)
        : const Color(0xFF7D9360).withValues(alpha: 0.88);
    canvas.drawPath(fullLeaf, Paint()..color = baseFillColor);

    // Metade superior bicolor (efeito aquarela igual à imagem de referência)
    final upperHalf = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        length * 0.25,
        -width * 0.58,
        length * 0.65,
        -width * 0.45 + tipY * 0.5,
        length,
        tipY,
      )
      ..quadraticBezierTo(length * 0.5, tipY * 0.4, 0, 0)
      ..close();

    final highlightColor = isPaleHalf
        ? (isDark
              ? const Color(0xFF5A7353).withValues(alpha: 0.72)
              : const Color(0xFFDCE3CE).withValues(alpha: 0.82))
        : (isDark
              ? const Color(0xFF425A3E).withValues(alpha: 0.62)
              : const Color(0xFF9FB283).withValues(alpha: 0.72));
    canvas.drawPath(upperHalf, Paint()..color = highlightColor);

    // Contorno botânico e nervura central
    final outlineColor = isDark
        ? const Color(0xFF8AA674)
        : const Color(0xFF42562C);
    final outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (length * 0.016).clamp(1.2, 2.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fullLeaf, outlinePaint);

    // Nervura central (vein)
    final midrib = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, tipY * 0.4, length * 0.86, tipY * 0.88);
    canvas.drawPath(midrib, outlinePaint);

    canvas.restore();
  }

  void _drawBerry(
    Canvas canvas, {
    required Offset stemStart,
    required Offset center,
    required double radius,
  }) {
    final stemColor = isDark
        ? const Color(0xFF8AA674)
        : const Color(0xFF4A5E35);

    // Cabinho da frutinha
    final stemPaint = Paint()
      ..color = stemColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (radius * 0.22).clamp(1.0, 1.8)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(stemStart, center, stemPaint);

    // Corpo da frutinha rosada em degradê suave
    final berryRect = Rect.fromCircle(center: center, radius: radius);
    final berryPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        radius: 0.95,
        colors: isDark
            ? const [Color(0xFFE5A8A3), Color(0xFFC47F7A)]
            : const [Color(0xFFF1C0BC), Color(0xFFDF9E99), Color(0xFFCE8882)],
      ).createShader(berryRect);

    canvas.drawCircle(center, radius, berryPaint);

    // Pequeno ponto escuro na extremidade da frutinha (cálice botânico)
    final dir = center - stemStart;
    final dist = dir.distance;
    final unit = dist > 0 ? dir / dist : const Offset(1, 0);
    final calyxPos = center + unit * (radius * 0.52);

    canvas.drawCircle(
      calyxPos,
      radius * 0.22,
      Paint()..color = const Color(0xFF8E5450),
    );
  }

  @override
  bool shouldRepaint(covariant BotanicalBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
