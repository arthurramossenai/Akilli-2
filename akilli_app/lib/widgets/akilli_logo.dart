import 'package:flutter/material.dart';

/// Widget que desenha o logo Akilli usando CustomPainter (sem depender de SVG).
/// Baseado no logo-sem-fundo.svg: um "A" estilizado com um ponto.
class AkilliLogo extends StatelessWidget {
  final double size;
  final Color color;

  const AkilliLogo({
    Key? key,
    this.size = 120,
    this.color = const Color(0xFF364025),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (178 / 160), // preservar proporção do SVG original
      child: CustomPaint(
        painter: _AkilliLogoPainter(color: color),
      ),
    );
  }
}

class _AkilliLogoPainter extends CustomPainter {
  final Color color;

  _AkilliLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Escala baseada no viewBox original: 160 x 178
    final double sx = size.width / 160;
    final double sy = size.height / 178;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0 * sx
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Traço 1: O "A" — arco da esquerda ao topo ao direito
    final path1 = Path()
      ..moveTo(10.418 * sx, 167.125 * sy)
      ..cubicTo(
        30 * sx, 100 * sy,
        55 * sx, 30 * sy,
        70 * sx, 12.7 * sy,
      )
      ..cubicTo(
        73 * sx, 8 * sy,
        76 * sx, 8 * sy,
        78 * sx, 12.8 * sy,
      )
      ..cubicTo(
        95 * sx, 60 * sy,
        110 * sx, 120 * sy,
        123.235 * sx, 167.125 * sy,
      );
    canvas.drawPath(path1, strokePaint);

    // Traço 2: A barra diagonal do "A"
    canvas.drawLine(
      Offset(10.418 * sx, 167.125 * sy),
      Offset(129.502 * sx, 79.378 * sy),
      strokePaint,
    );

    // Ponto do logo
    canvas.drawCircle(
      Offset(149.71 * sx, 66.483 * sy),
      10.01 * sx,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
