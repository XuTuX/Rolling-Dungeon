import 'dart:math';
import 'package:flutter/material.dart';
import 'package:circle_war/constant.dart';

// --- Background Painter ---
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    const double gridSize = 40.0;

    // Draw Grid
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw some random "Filled" cells to hint at gameplay
    final random = Random(42); // Fixed seed for consistent pattern
    final cellPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final cx = random.nextInt((size.width / gridSize).floor());
      final cy = random.nextInt((size.height / gridSize).floor());
      final color = regionColors[random.nextInt(regionColors.length)];

      cellPaint.color = color.withValues(alpha: 0.2);
      // Draw a rounded rect in the cell
      final rect = Rect.fromLTWH(
          cx * gridSize + 4, cy * gridSize + 4, gridSize - 8, gridSize - 8);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)), cellPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
