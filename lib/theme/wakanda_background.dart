import 'package:flutter/material.dart';
import 'wakanda_theme.dart';
import 'dart:math' as math;

class WakandaBackground extends StatelessWidget {
  final Widget child;

  const WakandaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      // Light Mode: Clean, subtle grey gradient
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade100],
          ),
        ),
        child: child,
      );
    }

    // Dark Mode: Wakanda Tribal Tech Pattern
    return CustomPaint(
      painter: _WakandaPatternPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WakandaTheme.blackMetal, WakandaTheme.onyx],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _WakandaPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = WakandaTheme.herbPurple.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    
    // Draw some subtle tribal geometric lines
    // Chevron / Arrow shapes
    
    final width = size.width;
    final height = size.height;
    
    // Top Left Pattern
    path.moveTo(0, height * 0.1);
    path.lineTo(width * 0.2, height * 0.15);
    path.lineTo(0, height * 0.2);
    
    // Top Right Pattern
    path.moveTo(width, height * 0.1);
    path.lineTo(width * 0.8, height * 0.15);
    path.lineTo(width, height * 0.2);
    
    // Center Tech Lines
    path.moveTo(width * 0.5, height * 0.3);
    path.lineTo(width * 0.5, height * 0.7);
    
    // Bottom Triangles
    path.moveTo(width * 0.2, height);
    path.lineTo(width * 0.25, height * 0.9);
    path.lineTo(width * 0.15, height * 0.9);
    path.close();

     path.moveTo(width * 0.8, height);
    path.lineTo(width * 0.75, height * 0.9);
    path.lineTo(width * 0.85, height * 0.9);
    path.close();

    canvas.drawPath(path, paint);
    
    // Add some random tech dots
    final dotPaint = Paint()..color = WakandaTheme.vibranium.withOpacity(0.05);
    final random = math.Random(42); // Fixed seed for consistency
    for (int i = 0; i < 20; i++) {
        canvas.drawCircle(
            Offset(random.nextDouble() * width, random.nextDouble() * height), 
            2, 
            dotPaint
        );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
