import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../models/game_snapshot.dart';

class ObstacleComponent extends PositionComponent {
  final ObstacleSnapshot data;

  ObstacleComponent(this.data) {
    position = Vector2(data.x, data.y);
    width = data.radius * 2;
    height = data.radius * 2;
    anchor = Anchor.center;
    angle = data.rotation;
  }

  @override
  void render(Canvas canvas) {
    final r = data.radius;
    final paint = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..style = PaintingStyle.fill;

    // Sketchy Rock/Box shape
    final path = Path();
    path.moveTo(-r, -r * 0.8);
    path.lineTo(-r * 0.7, -r);
    path.lineTo(r * 0.8, -r * 0.9);
    path.lineTo(r, -r * 0.2);
    path.lineTo(r * 0.9, r * 0.8);
    path.lineTo(r * 0.2, r);
    path.lineTo(-r * 0.9, r * 0.7);
    path.close();

    canvas.drawPath(path, paint);

    // Ink outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );

    // Detail lines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawLine(Offset(-r * 0.4, -r * 0.4), Offset(-r * 0.1, -r * 0.1), linePaint);
    canvas.drawLine(Offset(r * 0.2, r * 0.2), Offset(r * 0.5, r * 0.5), linePaint);
  }
}
