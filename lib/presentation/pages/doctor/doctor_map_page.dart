import 'package:flutter/material.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';

class DoctorMapPage extends StatelessWidget {
  const DoctorMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DoctorMockScaffold(
      currentIndex: 2,
      appBar: const DoctorTopBar(
          title: 'MedTrace', leadingIcon: Icons.person_outline),
      backgroundColor: const Color(0xFFB8BDBD),
      extendBody: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: const _MapPatternPainter(),
              child: Container(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          const Positioned(
            left: 36,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MapFilter(
                    icon: Icons.filter_alt_outlined, label: 'Therapy Status'),
                SizedBox(height: 12),
                _MapFilter(icon: Icons.location_on_outlined, label: 'Region'),
              ],
            ),
          ),
          Positioned(
            right: 24,
            top: 24,
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LEGEND',
                      style: TextStyle(color: doctorMuted, fontSize: 12)),
                  SizedBox(height: 12),
                  _LegendDot(color: doctorDanger, label: 'Defaulted'),
                  SizedBox(height: 10),
                  _LegendDot(color: doctorTeal2, label: 'Active'),
                  SizedBox(height: 10),
                  _LegendDot(color: doctorMint, label: 'Completed'),
                ],
              ),
            ),
          ),
          const Positioned(
              left: 180,
              top: 260,
              child: _MapCluster(count: '3', color: doctorDanger)),
          const Positioned(
              left: 110,
              top: 390,
              child: _MapCluster(count: '', color: doctorTeal2, small: true)),
          const Positioned(
              right: 118,
              top: 440,
              child: _MapCluster(count: '12', color: doctorTeal2)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(36, 12, 36, 92),
              decoration: const BoxDecoration(
                color: doctorBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                border: Border(top: BorderSide(color: doctorBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: doctorBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Visible Cases Summary',
                          style: TextStyle(
                              color: doctorText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_up_rounded, color: doctorTeal),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Row(
                    children: [
                      Expanded(
                        child: _SummaryBox(value: '24', label: 'Total in View'),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _SummaryBox(
                          value: '3',
                          label: 'High Risk',
                          danger: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapFilter extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MapFilter({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: doctorTeal),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: doctorText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const Icon(Icons.keyboard_arrow_down_rounded, color: doctorMuted),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: doctorText, fontSize: 13)),
      ],
    );
  }
}

class _MapCluster extends StatelessWidget {
  final String count;
  final Color color;
  final bool small;

  const _MapCluster({
    required this.count,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 30.0 : 48.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String value;
  final String label;
  final bool danger;

  const _SummaryBox({
    required this.value,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: danger ? doctorDangerSoft : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: danger ? const Color(0xFFFF9D9D) : const Color(0xFFB7C3C3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: danger ? doctorDanger : doctorTeal,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: danger ? doctorDanger : doctorText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  const _MapPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFB6BBBB);
    canvas.drawRect(Offset.zero & size, bg);

    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.23)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    void drawPath(List<Offset> points, Paint paint) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }

    drawPath([
      Offset(0, size.height * 0.18),
      Offset(size.width * 0.32, size.height * 0.32),
      Offset(size.width * 0.55, size.height * 0.55),
      Offset(size.width, size.height * 0.72),
    ], road);
    drawPath([
      Offset(size.width * 0.85, 0),
      Offset(size.width * 0.64, size.height * 0.24),
      Offset(size.width * 0.48, size.height * 0.5),
      Offset(size.width * 0.28, size.height),
    ], road);
    drawPath([
      Offset(0, size.height * 0.62),
      Offset(size.width * 0.34, size.height * 0.48),
      Offset(size.width * 0.72, size.height * 0.28),
      Offset(size.width, size.height * 0.2),
    ], road);

    for (var i = 0; i < 16; i++) {
      final y = size.height * (0.1 + i * 0.045);
      drawPath([
        Offset(size.width * 0.05, y),
        Offset(size.width * 0.35, y + 24),
        Offset(size.width * 0.75, y - 8),
      ], minor);
    }
    for (var i = 0; i < 10; i++) {
      final x = size.width * (0.05 + i * 0.1);
      drawPath([
        Offset(x, 0),
        Offset(x + 38, size.height * 0.45),
        Offset(x - 18, size.height),
      ], minor);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPatternPainter oldDelegate) => false;
}
