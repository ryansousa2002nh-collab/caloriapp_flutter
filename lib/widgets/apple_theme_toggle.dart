import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';

/// Botão customizado no formato de Maçã para alternar o Modo Noturno / Claro.
///
/// - Modo Noturno: Maçã Inteira
/// - Modo Claro: Maçã Mordida
class AppleThemeToggle extends StatefulWidget {
  final double size;
  final bool showBackground;
  final VoidCallback? onToggled;

  const AppleThemeToggle({
    super.key,
    this.size = 28,
    this.showBackground = false,
    this.onToggled,
  });

  @override
  State<AppleThemeToggle> createState() => _AppleThemeToggleState();
}

class _AppleThemeToggleState extends State<AppleThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _biteAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final isDark = ThemeController.instance.isDarkMode;

    // Se isDark == true, biteProgress = 0.0 (maçã inteira)
    // Se isDark == false (modo claro), biteProgress = 1.0 (maçã mordida)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: isDark ? 0.0 : 1.0,
    );

    _biteAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.15), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
    ]).animate(_animController);

    ThemeController.instance.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    final isDark = ThemeController.instance.isDarkMode;
    if (isDark) {
      _animController.reverse(); // Volta para maçã inteira
    } else {
      _animController.forward(); // Transiciona para maçã mordida
    }
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    ThemeController.instance.toggleTheme();
    widget.onToggled?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;
        final tooltip = isDark
            ? 'Modo Noturno ativo (Clique para Modo Claro - Maçã Mordida)'
            : 'Modo Claro ativo (Clique para Modo Noturno - Maçã Inteira)';

        Widget appleWidget = AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: ApplePainter(
                  biteProgress: _biteAnimation.value,
                  isDark: isDark,
                ),
              ),
            );
          },
        );

        if (widget.showBackground) {
          appleWidget = Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bordaEscuro.withValues(alpha: 0.5) : AppColors.verdeClaro,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.bordaEscuro : AppColors.verdeBorda,
                width: 1.2,
              ),
            ),
            child: appleWidget,
          );
        }

        return Tooltip(
          message: tooltip,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(widget.size),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: appleWidget,
            ),
          ),
        );
      },
    );
  }
}

/// Item de menu para o Drawer com a maçã animada e status do tema
class AppleThemeDrawerTile extends StatelessWidget {
  const AppleThemeDrawerTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDarkMode;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.verdeFundoEscuro : AppColors.verdeClaro,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF065F46) : AppColors.verdeBorda,
            ),
          ),
          child: ListTile(
            dense: true,
            onTap: () => ThemeController.instance.toggleTheme(),
            leading: const AppleThemeToggle(size: 26),
            title: Text(
              isDark ? 'Modo Noturno' : 'Modo Claro',
              style: TextStyle(
                color: isDark ? const Color(0xFF6EE7B7) : AppColors.verdeEscuro,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              isDark ? 'Maçã inteira • Toque para modo claro' : 'Maçã mordida • Toque para modo noturno',
              style: TextStyle(
                color: isDark ? AppColors.textoSecundarioEscuro : AppColors.textoSecundario,
                fontSize: 11,
              ),
            ),
            trailing: Switch.adaptive(
              value: isDark,
              activeTrackColor: AppColors.verde,
              activeThumbColor: Colors.white,
              onChanged: (_) => ThemeController.instance.toggleTheme(),
            ),
          ),
        );
      },
    );
  }
}

/// Desenho vetorial de alta precisão da Maçã com suporte à mordida
class ApplePainter extends CustomPainter {
  final double biteProgress; // 0.0 (inteira) a 1.0 (mordida)
  final bool isDark;

  ApplePainter({
    required this.biteProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Caule / Cabinho da maçã
    final stemPath = Path();
    stemPath.moveTo(w * 0.50, h * 0.30);
    stemPath.cubicTo(w * 0.50, h * 0.16, w * 0.58, h * 0.10, w * 0.62, h * 0.06);

    final stemPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.08).clamp(1.5, 3.5)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(stemPath, stemPaint);

    // 2. Folha verde
    final leafPath = Path();
    leafPath.moveTo(w * 0.52, h * 0.20);
    leafPath.quadraticBezierTo(w * 0.72, h * 0.12, w * 0.84, h * 0.16);
    leafPath.quadraticBezierTo(w * 0.70, h * 0.28, w * 0.52, h * 0.20);
    leafPath.close();

    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.5, h * 0.1, w * 0.35, h * 0.2));

    canvas.drawPath(leafPath, leafPaint);

    // 3. Silhueta orgânica do corpo da maçã
    final applePath = Path();
    // Entalhe superior
    applePath.moveTo(w * 0.50, h * 0.32);
    // Ombro esquerdo
    applePath.cubicTo(w * 0.34, h * 0.20, w * 0.08, h * 0.26, w * 0.08, h * 0.50);
    // Barriga esquerda e base
    applePath.cubicTo(w * 0.08, h * 0.74, w * 0.22, h * 0.94, w * 0.40, h * 0.94);
    // Entalhe inferior central
    applePath.cubicTo(w * 0.46, h * 0.94, w * 0.48, h * 0.89, w * 0.50, h * 0.89);
    applePath.cubicTo(w * 0.52, h * 0.89, w * 0.54, h * 0.94, w * 0.60, h * 0.94);
    // Barriga direita e ombro direito
    applePath.cubicTo(w * 0.78, h * 0.94, w * 0.92, h * 0.74, w * 0.92, h * 0.50);
    applePath.cubicTo(w * 0.92, h * 0.26, w * 0.66, h * 0.20, w * 0.50, h * 0.32);
    applePath.close();

    // 4. Caminho da Mordida (Bite)
    final bitePath = Path();
    if (biteProgress > 0.001) {
      final r1 = w * 0.17 * biteProgress;
      final r2 = w * 0.19 * biteProgress;
      final r3 = w * 0.16 * biteProgress;

      bitePath.addOval(Rect.fromCircle(center: Offset(w * 0.90, h * 0.42), radius: r1));
      bitePath.addOval(Rect.fromCircle(center: Offset(w * 0.84, h * 0.55), radius: r2));
      bitePath.addOval(Rect.fromCircle(center: Offset(w * 0.90, h * 0.68), radius: r3));
    }

    // 5. Aplica a subtração da mordida
    Path finalBodyPath = applePath;
    if (biteProgress > 0.001) {
      finalBodyPath = Path.combine(PathOperation.difference, applePath, bitePath);
    }

    // 6. Pintura do corpo da maçã com degradê
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Vermelho vibrante
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(finalBodyPath, bodyPaint);

    // 7. Brilho especular (Gloss) no ombro esquerdo
    final glossPath = Path();
    glossPath.moveTo(w * 0.22, h * 0.38);
    glossPath.cubicTo(w * 0.16, h * 0.48, w * 0.18, h * 0.62, w * 0.26, h * 0.72);

    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.06).clamp(1.2, 2.5)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(glossPath, glossPaint);

    // 8. Borda clara da polpa exposta da maçã na mordida
    if (biteProgress > 0.05) {
      final fleshPaint = Paint()
        ..color = const Color(0xFFFEF3C7).withValues(alpha: (biteProgress * 0.95).clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.04).clamp(1.0, 2.0)
        ..strokeCap = StrokeCap.round;

      canvas.save();
      canvas.clipPath(applePath);
      canvas.drawPath(bitePath, fleshPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ApplePainter oldDelegate) {
    return oldDelegate.biteProgress != biteProgress || oldDelegate.isDark != isDark;
  }
}
