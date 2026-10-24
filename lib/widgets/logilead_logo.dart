import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogiLeadLogo extends StatelessWidget {
  final double height;
  final bool isDark;
  final bool showTextFallback;

  const LogiLeadLogo({
    super.key,
    this.height = 36,
    this.isDark = false,
    this.showTextFallback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logilead_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (!showTextFallback) {
          return Icon(Icons.token, size: height, color: const Color(0xFF0066FF));
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: height * 0.72,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(
                    text: 'Logi',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF071739),
                    ),
                  ),
                  const TextSpan(
                    text: 'Lead',
                    style: TextStyle(
                      color: Color(0xFF0066FF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
