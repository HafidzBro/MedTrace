import 'package:flutter/material.dart';

class MedTraceBrandMark extends StatelessWidget {
  static const assetPath = 'assets/icons/app_logo.png';

  final double size;
  final bool monochrome;

  const MedTraceBrandMark({
    super.key,
    this.size = 120,
    this.monochrome = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'MedTrace logo',
        color: monochrome ? Colors.white : null,
        colorBlendMode: monochrome ? BlendMode.srcIn : null,
      ),
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
