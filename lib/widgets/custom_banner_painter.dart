import 'package:flutter/material.dart';

class BannerBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. High-tech LogiLead Deep Navy to Royal Blue Gradient
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF071739), // LogiLead Deep Navy
        Color(0xFF0C2556), // Mid Indigo
        Color(0xFF0047BA), // Electric Blue Transition
        Color(0xFF0066FF), // LogiLead Royal Blue
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    );
    final bgPaint = Paint()..shader = bgGradient.createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // 2. Ambient Cyber Waves / Modern Flow
    final wavePaint1 = Paint()
      ..color = const Color(0xFF00A3FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(size.width * 0.3, 0);
    path1.cubicTo(
      size.width * 0.5,
      size.height * 0.8,
      size.width * 0.7,
      size.height * 0.1,
      size.width,
      size.height * 0.6,
    );
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, wavePaint1);

    final wavePaint2 = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(size.width * 0.5, size.height);
    path2.cubicTo(
      size.width * 0.65,
      size.height * 0.2,
      size.width * 0.85,
      size.height * 0.9,
      size.width,
      size.height * 0.3,
    );
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, wavePaint2);

    // 3. Diagonal Brand Slash Accents (Matching LogiLead 'g' slash)
    final slashPaint = Paint()
      ..color = const Color(0xFF00A3FF).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final startX = size.width - 240.0 + (i * 45.0);
      final slashPath = Path()
        ..moveTo(startX, size.height + 10)
        ..lineTo(startX + 35, -10)
        ..lineTo(startX + 50, -10)
        ..lineTo(startX + 15, size.height + 10)
        ..close();
      canvas.drawPath(slashPath, slashPaint);
    }

    // 4. Logistics & Enterprise Network Grid & Glowing Nodes
    _drawLogisticsNodes(canvas, size);
  }

  void _drawLogisticsNodes(Canvas canvas, Size size) {
    if (size.width < 500) return;

    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final nodePaint = Paint()
      ..color = const Color(0xFF00A3FF).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Network connection points
    final nodes = [
      Offset(size.width - 220, size.height * 0.35),
      Offset(size.width - 160, size.height * 0.65),
      Offset(size.width - 90, size.height * 0.28),
      Offset(size.width - 40, size.height * 0.72),
      Offset(size.width - 290, size.height * 0.55),
    ];

    // Draw connecting route lines
    for (int i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i + 1], linePaint);
    }
    canvas.drawLine(nodes[0], nodes[2], linePaint);
    canvas.drawLine(nodes[1], nodes[4], linePaint);

    // Draw glowing node points
    for (final node in nodes) {
      canvas.drawCircle(node, 7, nodePaint);
      canvas.drawCircle(node, 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
