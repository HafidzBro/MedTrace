import 'package:flutter/material.dart';

class MedTraceBrandMark extends StatelessWidget {
  final double size;
  final bool monochrome;

  const MedTraceBrandMark({
    super.key,
    this.size = 120,
    this.monochrome = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MedTraceBrandMarkPainter(monochrome: monochrome),
    );
  }
}

class MedTraceWordmark extends StatelessWidget {
  final double fontSize;
  final bool monochrome;

  const MedTraceWordmark({
    super.key,
    this.fontSize = 42,
    this.monochrome = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = monochrome ? Colors.white : const Color(0xFF00436B);
    final accentColor = monochrome ? Colors.white : const Color(0xFF12BFA4);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
          fontFamily: 'Roboto',
        ),
        children: [
          TextSpan(text: 'Med', style: TextStyle(color: textColor)),
          TextSpan(text: 'Trace', style: TextStyle(color: accentColor)),
        ],
      ),
    );
  }
}

class _MedTraceBrandMarkPainter extends CustomPainter {
  final bool monochrome;

  const _MedTraceBrandMarkPainter({required this.monochrome});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final white = Paint()..color = Colors.white;
    final teal = Paint()..color = const Color(0xFF12BFA4);
    final navy = Paint()..color = const Color(0xFF00436B);
    final markPaint = monochrome ? white : teal;
    final lowerPaint = monochrome ? white : navy;

    final cross = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + s * 0.02),
            width: s * 0.45,
            height: s * 0.86,
          ),
          Radius.circular(s * 0.1),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - s * 0.04),
            width: s * 0.86,
            height: s * 0.45,
          ),
          Radius.circular(s * 0.1),
        ),
      );

    canvas.drawPath(cross, markPaint);

    if (!monochrome) {
      final lower = RRect.fromRectAndCorners(
        Rect.fromLTWH(s * 0.32, s * 0.55, s * 0.36, s * 0.31),
        bottomLeft: Radius.circular(s * 0.1),
        bottomRight: Radius.circular(s * 0.1),
      );
      canvas.drawRRect(lower, lowerPaint);
    }

    final trachea = Paint()
      ..color = monochrome ? const Color(0xFF00565A) : Colors.white
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx, s * 0.23),
      Offset(center.dx, s * 0.5),
      trachea,
    );

    final leftLung = Path()
      ..moveTo(center.dx - s * 0.02, s * 0.48)
      ..cubicTo(s * 0.37, s * 0.55, s * 0.34, s * 0.68, s * 0.24, s * 0.73)
      ..cubicTo(s * 0.23, s * 0.58, s * 0.28, s * 0.47, s * 0.44, s * 0.4);

    final rightLung = Path()
      ..moveTo(center.dx + s * 0.02, s * 0.48)
      ..cubicTo(s * 0.63, s * 0.55, s * 0.66, s * 0.68, s * 0.76, s * 0.73)
      ..cubicTo(s * 0.77, s * 0.58, s * 0.72, s * 0.47, s * 0.56, s * 0.4);

    final lungPaint = Paint()
      ..color = monochrome ? const Color(0xFF00565A) : Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftLung, lungPaint);
    canvas.drawPath(rightLung, lungPaint);

    final branchPaint = Paint()
      ..color = monochrome ? const Color(0xFF00565A) : markPaint.color
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(center.dx, s * 0.5), Offset(s * 0.42, s * 0.62), branchPaint);
    canvas.drawLine(
        Offset(center.dx, s * 0.5), Offset(s * 0.58, s * 0.62), branchPaint);
  }

  @override
  bool shouldRepaint(covariant _MedTraceBrandMarkPainter oldDelegate) {
    return oldDelegate.monochrome != monochrome;
  }
}
