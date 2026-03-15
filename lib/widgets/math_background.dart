import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/colors.dart';

class MathBgPainter extends CustomPainter {
  final double t;
  MathBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size s) {
    final symbols = ['∑','π','√','∞','∫','Δ','θ','≠','α','β','λ','÷'];
    final rng = math.Random(42);
    final positions = List.generate(14, (i) =>
      Offset(rng.nextDouble() * s.width, rng.nextDouble() * s.height));

    for (int i = 0; i < positions.length; i++) {
      final dy = math.sin((t + i * 0.4) * 2 * math.pi) * 12;
      final op = (0.04 + math.sin((t * 0.7 + i * 0.4) * 2 * math.pi) * 0.02).clamp(0.02, 0.07);
      final tp = TextPainter(
        text: TextSpan(text: symbols[i % symbols.length],
          style: TextStyle(color: LC.pLight.withOpacity(op),
            fontSize: 16 + rng.nextDouble() * 12, fontWeight: FontWeight.w300)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(positions[i].dx, positions[i].dy + dy));
    }

final orbs = [
      (0.1, 0.1, 130.0, LC.primary),
      (0.9, 0.15, 100.0, LC.accent),
      (0.85, 0.8, 140.0, LC.primary),
      (0.05, 0.75, 80.0, LC.rose),
    ];
    for (final (x, y, r, color) in orbs) {
      final dy = math.sin((t + x + y) * 2 * math.pi) * 14;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(s.width * x, s.height * y + dy), radius: r));
      canvas.drawCircle(Offset(s.width * x, s.height * y + dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(MathBgPainter o) => o.t != t;
}

class MathBackground extends StatelessWidget {
  final Widget child;
  final AnimationController controller;
  const MathBackground({super.key, required this.child, required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [LC.bg1, LC.bg2, LC.bg3], stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) => CustomPaint(
            painter: MathBgPainter(controller.value), size: size),
        ),
        ...List.generate(20, (i) {
          final rng = math.Random(i * 31);
          return Positioned(
            left: rng.nextDouble() * size.width,
            top: rng.nextDouble() * size.height,
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final b = (math.sin((controller.value * 2 * math.pi) + i * 0.7) + 1) / 2;
                return Container(
                  width: rng.nextDouble() * 2 + 0.5,
                  height: rng.nextDouble() * 2 + 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06 + b * 0.3),
                  ),
                );
              },
            ),
          );
        }),
        child,
      ],
    );
  }
}



